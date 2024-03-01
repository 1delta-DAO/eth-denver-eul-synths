// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "evc/EthereumVaultConnector.sol";
import "../../src/vaults/solmate/VaultSimple.sol";
import {ICSPFactory, IRateProvider} from "../../src/balancer-adapter/interfaces/ICSPFactory.sol";
import {IBalancerVault, JoinPoolRequest, IAsset, SingleSwap, SwapKind, FundManagement} from "../../src/balancer-adapter/interfaces/IVault.sol";
import {BalancerSepoliaAddresses} from "./BalancerSepoliaAddresses.sol";
import {Fiat} from "../ERC20/Fiat.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";
import {IBalancerPool} from "../../src/balancer-adapter/interfaces/IBalancerPool.sol";
import {StablePoolUserData} from "../../src/balancer-adapter/interfaces/StablePoolUserData.sol";

// run via `forge test -vv --match-test "create"`
contract BalancerCreateTest is Test, BalancerSepoliaAddresses {
    IEVC _evc_;

    Fiat USDC;
    Fiat eUSD;
    Fiat DAI;

    ICSPFactory cspFactory;
    IBalancerVault balancerVault;

    uint256 constant MAX_VAL = type(uint).max;

    function setUp() public {
        vm.createSelectFork({
            blockNumber: 5_388_756,
            urlOrAlias: "https://rpc.ankr.com/eth_sepolia"
        });

        // stablecoins creation, they already mint to the caller
        USDC = new Fiat("USDC", "USD Coin", 6);
        eUSD = new Fiat("eUSD", "Euler Vault Dollars", 18);
        DAI = new Fiat("DAI", "DAI  Stablecoin", 18);

        // balancer contracts
        cspFactory = ICSPFactory(CSP_FACTORY);
        balancerVault = IBalancerVault(BALANCER_VAULT);
    }

    function test_create_cs_pool() public {
        // 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f 0x2e234DAe75C793f67A35089C9d99245E1C58470b 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
        // console.log(address(USDC), address(eUSD), address(DAI));
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = IERC20(address(eUSD));
        tokens[1] = IERC20(address(USDC));
        tokens[2] = IERC20(address(DAI));

        // do max approvals for joins and swaps
        eUSD.approve(BALANCER_VAULT, MAX_VAL);
        USDC.approve(BALANCER_VAULT, MAX_VAL);
        DAI.approve(BALANCER_VAULT, MAX_VAL);
        address pool;
        {
            IRateProvider[] memory rateProviders = new IRateProvider[](3);
            uint256[] memory tokenRateCacheDurations = new uint256[](3);
            uint256 amplificationParameter = 2000;
            uint256 swapFeePercentage = 0.001e18;
            bool exemptFromYieldProtocolFeeFlag = true;
            address owner = address(this);
            pool = cspFactory.create(
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
        }
        console.log(pool);

        bytes32 poolId = IBalancerPool(pool).getPoolId();

        /**
         *  Balancer CSPs add the pool token to the registered tokens
         *  The token might be added in the middle
         */
        (tokens, , ) = balancerVault.getPoolTokens(poolId);
        // check the order of the tokens
        console.log("Tokens", tokens.length);
        console.log("Token0", address(tokens[0]));
        console.log("Token1", address(tokens[1]));
        console.log("Token2", address(tokens[2]));
        console.log("Token3", address(tokens[3]));

        // we get the right order from balancer
        IAsset[] memory assets = new IAsset[](4);
        assets[0] = IAsset(address(tokens[0]));
        assets[1] = IAsset(address(tokens[1]));
        assets[2] = IAsset(address(tokens[2]));
        assets[3] = IAsset(address(tokens[3]));

        // maximums
        uint256[] memory maxAmountsIn = fillWith(type(uint).max, 4);

        bytes memory userData = abi.encode(
            StablePoolUserData.JoinKind.INIT,
            // these are the balances to be drawn
            createArr4(1e18, 0, 1e6, 3.0e18), // index 1 is the BPT
            uint256(0)
        );
        JoinPoolRequest memory request = JoinPoolRequest(
            assets, // IAsset[] assets;
            maxAmountsIn, // uint256[] maxAmountsIn;
            userData, // bytes userData;
            false // bool fromInternalBalance;
        );

        balancerVault.joinPool(
            poolId, // bytes32 poolId,
            address(this), // address sender,
            address(this), // address recipient,
            request // JoinPoolRequest memory request
        );
        console.log("Joined");

        uint poolBal = IBalancerPool(pool).balanceOf(address(this));
        console.log("BPT balance", poolBal);

        SingleSwap memory singleSwap = SingleSwap(
            poolId, // bytes32 poolId;
            SwapKind.GIVEN_IN, // SwapKind kind;
            IAsset(address(eUSD)), // IAsset assetIn;
            IAsset(address(DAI)), // IAsset assetOut;
            1e18, // uint256 amount;
            "0x" // bytes userData;
        );

        FundManagement memory funds = FundManagement(
            address(this), // address sender;
            false, // bool fromInternalBalance;
            payable(address(this)), // address payable recipient;
            false // bool toInternalBalance;
        );
        uint balanceOut = DAI.balanceOf(address(this));
        balancerVault.swap(
            singleSwap, // SingleSwap memory singleSwap,
            funds, // FundManagement memory funds,
            0, // uint256 limit,
            type(uint).max // uint256 deadline
        );

        balanceOut = DAI.balanceOf(address(this)) - balanceOut;
        console.log("received", balanceOut);

        userData = abi.encode(
            StablePoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            // these are the balances to be drawn
            createArr3(10.0e18, 1e6, 30.0e18), // index 1 is the BPT
            uint256(0)
        );
        request = JoinPoolRequest(
            assets, // IAsset[] assets;
            maxAmountsIn, // uint256[] maxAmountsIn;
            userData, // bytes userData;
            false // bool fromInternalBalance;
        );

        // we get the right order from balancer
        assets = new IAsset[](3);
        assets[0] = IAsset(address(eUSD));
        assets[1] = IAsset(address(USDC));
        assets[2] = IAsset(address(DAI));
        // regular join and NO init
        balancerVault.joinPool(
            poolId, // bytes32 poolId,
            address(this), // address sender,
            address(this), // address recipient,
            request // JoinPoolRequest memory request
        );
        console.log("joined exactIn");
        poolBal = IBalancerPool(pool).balanceOf(address(this)) - poolBal;
        console.log("BPT balance increased:", poolBal);
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

    function createArr3(
        uint256 value0,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256[] memory target) {
        target = new uint256[](3);
        target[0] = value0;
        target[1] = value1;
        target[2] = value2;
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
}
