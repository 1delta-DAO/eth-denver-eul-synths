// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {ICSPFactoryGeneral, IRateProvider} from "./interfaces/ICSPFactory.sol";
import {IBalancerVaultGeneral, JoinPoolRequest, SingleSwap, SwapKind, FundManagement} from "./interfaces/IVaultGeneral.sol";
import {StablePoolUserData} from "./interfaces/StablePoolUserData.sol";
import {IBalancerPool} from "./interfaces/IBalancerPool.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IMinimalVault} from "./interfaces/IMinimalVault.sol";
import "../../lib/ethereum-vault-connector/src/utils/EVCUtil.sol";

contract BalancerAdapter is IPriceOracle, EVCUtil {
    address public pool;
    bytes32 public poolId;

    address public immutable cspFactory;
    address public immutable balancerVault;
    address[] pooledTokens;
    // ordered arrays
    uint256[] private multipliers;
    uint256[] private decimalScales;
    address[] oracles;
    address[] pooledTokensClean;
    uint256 BALANCER_ASSET_LENGTH;
    // sorted like balaner
    uint256[] balancerScalingFactors;
    address[] balancerRateProviders;
    // maps token to balancer tokenIndex
    mapping(address => uint8) tokenToIndex;
    mapping(address => uint8) tokenToIndexExtended;
    // supply downscaling
    uint SUPPLY_DOWNCALING;

    uint256 constant PRICE_SCALE = 1e18;
    uint256 constant BPT_SCALE = 1e18;

    constructor(
        address _cspFactory,
        address _balancerVault,
        address evc
    ) EVCUtil(IEVC(evc)) {
        cspFactory = _cspFactory;
        balancerVault = _balancerVault;
        SUPPLY_DOWNCALING = 1;
    }

    function getDecimalScalesAndTokens()
        external
        view
        returns (address[] memory _tokens, uint256[] memory _scales)
    {
        _tokens = pooledTokensClean;
        _scales = decimalScales;
    }

    function getOriginalDecimalScalesAndTokens()
        external
        view
        returns (address[] memory _tokens, uint256[] memory _scales)
    {
        _tokens = pooledTokens;
        _scales = balancerScalingFactors;
    }

    function createPool(
        address[] memory tokens,
        address[] memory rateProviders
    ) external {
        require(pool == address(0), "Pool already deployed");

        uint256[] memory tokenRateCacheDurations = new uint256[](3);
        uint256 amplificationParameter = 2000;
        uint256 swapFeePercentage = 0.0003e18; // 3 bp fee
        bool exemptFromYieldProtocolFeeFlag = true;
        address owner = address(this);
        pool = ICSPFactoryGeneral(cspFactory).create(
            "3eUSD", // string memory name,
            "3 Euler Bootstrapped USD Pool", // string memory symbol,
            tokens, // IERC20[] memory tokens,
            amplificationParameter, // uint256 amplificationParameter,
            rateProviders, // IRateProvider[] memory rateProviders,
            tokenRateCacheDurations, // uint256[] memory tokenRateCacheDurations,
            exemptFromYieldProtocolFeeFlag, // bool exemptFromYieldProtocolFeeFlag,
            swapFeePercentage, // uint256 swapFeePercentage,
            owner, // address owner,
            0x0 // bytes32 salt
        );
        BALANCER_ASSET_LENGTH = tokens.length;
        balancerRateProviders = IBalancerPool(pool).getRateProviders();
        poolId = IBalancerPool(pool).getPoolId();
        /**
         *  Balancer CSPs add the pool token to the registered tokens
         *  The token might be added in the middle
         */
        (address[] memory tokensAll, , ) = IBalancerVaultGeneral(balancerVault)
            .getPoolTokens(poolId);
        pooledTokens = tokensAll;
        // do a sorted insert and create mapping
        mapTokens(tokens, rateProviders);

        // approve vault for future txns
        address vault = balancerVault;
        for (uint i; i < tokens.length; ) {
            IERC20(tokens[i]).approve(vault, type(uint).max);
            unchecked {
                i++;
            }
        }
    }

    /**
     * Initialize the Balancer pool
     * @param amounts amounts to be deposited in order, padded with pool token
     */
    function initializePool(
        uint256[] memory amounts,
        address recipient
    ) external {
        // check the order of the tokens

        bytes memory userData = abi.encode(
            StablePoolUserData.JoinKind.INIT,
            // these are the balances to be drawn
            amounts, // index 1 is the BPT
            uint256(0) // not used for init
        );
        JoinPoolRequest memory request = JoinPoolRequest(
            pooledTokens, // IAsset[] assets;
            fillWith(type(uint).max, 4), // uint256[] maxAmountsIn;
            userData, // bytes userData;
            false // bool fromInternalBalance;
        );

        IBalancerVaultGeneral(balancerVault).joinPool(
            poolId, // bytes32 poolId,
            address(this), // address sender,
            recipient, // address recipient,
            request // JoinPoolRequest memory request
        );
    }

    function depositTo(uint256[] memory amounts, address recipient) external {
        bytes memory userData = abi.encode(
            StablePoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            // these are the balances to be drawn
            amounts,
            uint256(0)
        );
        JoinPoolRequest memory request = JoinPoolRequest(
            pooledTokens, // IAsset[] assets;
            fillWith(type(uint).max, 4), // uint256[] maxAmountsIn;
            userData, // bytes userData;
            false // bool fromInternalBalance;
        );

        // regular join and NO init
        IBalancerVaultGeneral(balancerVault).joinPool(
            poolId, // bytes32 poolId,
            address(this), // address sender,
            recipient, // address recipient,
            request // JoinPoolRequest memory request
        );
    }

    function doCheckAccountStatus(
        address,
        address[] calldata
    ) internal view virtual {
        // no need to do anything here because the vault does not allow borrowing
    }

    /**
     * pulls funds from the caller;
     */
    function facilitateLeveragedDeposit(
        address depositAsset,
        uint256 depositAmount,
        address vault,
        address recipient
    ) external callThroughEVC returns (uint256 bptAmountOrShares) {
        address sender = EVCUtil._msgSender();
        // pull assets
        IERC20(depositAsset).transferFrom(sender, address(this), depositAmount);
        bool vaultProvided = vault != address(0);
        address balancerPTRecipient = vaultProvided ? address(this) : recipient;
        uint256[] memory amountsToDeposit = fetchAmounts();
        bytes memory userData = abi.encode(
            StablePoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            // these are the balances to be drawn
            amountsToDeposit,
            uint256(0)
        );
        JoinPoolRequest memory request = JoinPoolRequest(
            pooledTokens, // IAsset[] assets;
            fillWith(type(uint).max, 4), // uint256[] maxAmountsIn;
            userData, // bytes userData;
            false // bool fromInternalBalance;
        );

        // regular join and NO init
        IBalancerVaultGeneral(balancerVault).joinPool(
            poolId, // bytes32 poolId,
            address(this), // address sender,
            balancerPTRecipient, // address recipient,
            request // JoinPoolRequest memory request
        );
        IERC20 poolToken = IERC20(pool);
        // fetch BPT balance
        bptAmountOrShares = poolToken.balanceOf(address(this));

        // deposit to vault for recipient if provided
        if (vaultProvided) {
            poolToken.approve(vault, type(uint).max);
            bptAmountOrShares = IMinimalVault(vault).deposit(
                bptAmountOrShares,
                recipient
            );
            poolToken.approve(vault, 0);
        }
    }

    // implements the oracles for vaults
    function getQuote(
        uint256 amount, // amount is in BPT has 18 decimals
        address, // base is BPT
        address quote
    ) public view returns (uint256 out) {
        uint256 poolTokenPrice = getPrice(); // expected to have same scale as getRate
        uint outIndex = tokenToIndexExtended[quote];
        out =
            (poolTokenPrice * amount) /
            IRateProvider(balancerRateProviders[outIndex]).getRate() /
            balancerScalingFactors[outIndex];
    }

    // implements the oracles for vaults
    function getQuotes(
        uint256 amount,
        address, // base is BPT
        address quote
    ) external view returns (uint256 bidOut, uint256 askOut) {
        bidOut = getQuote(amount, address(0), quote);
        askOut = bidOut;
    }

    /**
     * Get the price of a BPT expressed in USD
     * We calculate the dollars supplied and divide by the
     * total spply of the BPT
     */
    function getPrice() public view returns (uint256) {
        (
            address[] memory tokens,
            uint256[] memory balances,

        ) = IBalancerVaultGeneral(balancerVault).getPoolTokens(poolId);
        uint256 poolQuotedAmount;
        uint256 counter;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != pool) {
                address oracle = balancerRateProviders[counter];
                if (oracle != address(0)) {
                    // prices have 18 decimals
                    uint256 price = IRateProvider(
                        balancerRateProviders[counter]
                    ).getRate();
                    require(price > 0, "Invalid price");
                    uint256 dollarAmount = (balances[counter] *
                        uint256(price) *
                        balancerScalingFactors[counter]) / PRICE_SCALE;
                    poolQuotedAmount += dollarAmount;
                } else {
                    // no rate provider means that the price is 1:1
                    uint256 dollarAmount = balances[counter] *
                        balancerScalingFactors[counter]; // we adjust to 18 decimals
                    poolQuotedAmount += dollarAmount;
                }
            }
            counter++;
        }
        // balancer deviates here and uses getActualSupply instead of totalSupply
        uint256 totalSupply = IBalancerPool(pool).getActualSupply();

        return
            totalSupply > 0 ? (poolQuotedAmount * BPT_SCALE) / totalSupply : 0;
    }

    // inserts the tokens in a without BPT
    function mapTokens(
        address[] memory underlyngsUnsorted,
        address[] memory oraclesUnsorted
    ) internal {
        // balancer sorts them, but includes the BPT
        (address[] memory tokens, , ) = IBalancerVaultGeneral(balancerVault)
            .getPoolTokens(poolId);

        uint256 insertCount;
        uint targetLength = tokens.length - 1;
        pooledTokensClean = new address[](targetLength);
        oracles = new address[](targetLength);
        multipliers = new uint256[](targetLength);
        decimalScales = new uint256[](targetLength);
        balancerScalingFactors = new uint256[](targetLength + 1);
        uint downscaler = 1;
        for (uint256 i; i < tokens.length; i++) {
            address currentToken = tokens[i];
            uint decimalScale = 10 ** IERC20(tokens[i]).decimals();
            balancerScalingFactors[i] = 1e18 / decimalScale;
            downscaler *= balancerScalingFactors[i];
            tokenToIndexExtended[currentToken] = uint8(i);
            for (uint256 j; j < underlyngsUnsorted.length; j++) {
                address toInsert = underlyngsUnsorted[j];
                if (currentToken == toInsert) {
                    pooledTokensClean[insertCount] = toInsert;
                    oracles[insertCount] = oraclesUnsorted[j];
                    tokenToIndex[currentToken] = uint8(insertCount);
                    decimalScales[insertCount] = decimalScale;
                    multipliers[insertCount] = 1e18 / decimalScale;
                    insertCount++;
                }
            }
        }
        SUPPLY_DOWNCALING = downscaler;
    }

    // organize unordered assets array for balaner parametrization
    function parametrizeBalancerInput(
        address[] memory assetsUnsorted,
        uint[] memory amountsUnsorted
    ) internal view returns (uint256[] memory amountsSorted) {
        amountsSorted = new uint256[](BALANCER_ASSET_LENGTH);
        require(
            assetsUnsorted.length == amountsUnsorted.length,
            "Length Mismatch"
        );
        for (uint i; i < assetsUnsorted.length; i++) {
            uint8 index = tokenToIndex[assetsUnsorted[i]];
            amountsSorted[index] = amountsUnsorted[i];
        }
    }

    // fetch amounts in this contract for balaner parametrization
    function fetchAmounts()
        internal
        view
        returns (uint256[] memory amountsSorted)
    {
        uint256 assetLength = BALANCER_ASSET_LENGTH;
        amountsSorted = new uint256[](BALANCER_ASSET_LENGTH);
        for (uint i; i < assetLength; i++) {
            amountsSorted[i] = IERC20(pooledTokensClean[i]).balanceOf(
                address(this)
            );
        }
    }

    function createArr4(
        uint256 value0,
        uint256 value1,
        uint256 value2,
        uint256 value3
    ) internal pure returns (uint256[] memory target) {
        target = new uint256[](4);
        target[0] = value0;
        target[1] = value1;
        target[2] = value2;
        target[3] = value3;
    }

    // create same value array
    function fillWith(
        uint256 value,
        uint length
    ) internal pure returns (uint256[] memory target) {
        target = new uint256[](length);
        for (uint i; i < length; i++) {
            target[i] = value;
        }
    }

    function name() external pure returns (string memory) {
        return "Balancer Adapter";
    }
}
