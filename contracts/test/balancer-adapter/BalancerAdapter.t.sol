// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "evc/EthereumVaultConnector.sol";
import "../../src/vaults/solmate/VaultSimple.sol";
import {ICSPFactory, IRateProvider} from "../../src/balancer-adapter/interfaces/ICSPFactory.sol";
import {IBalancerVaultGeneral, JoinPoolRequest, SingleSwap, SwapKind, FundManagement} from "../../src/balancer-adapter/interfaces/IVaultGeneral.sol";
import {BalancerSepoliaAddresses} from "./BalancerSepoliaAddresses.sol";
import {ChainLinkFeedAddresses} from "./ChainLinkFeedAddresses.sol";
import {Fiat} from "../ERC20/Fiat.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";
import {IBalancerPool} from "../../src/balancer-adapter/interfaces/IBalancerPool.sol";
import {StablePoolUserData} from "../../src/balancer-adapter/interfaces/StablePoolUserData.sol";
import {BalancerAdapter} from "../../src/balancer-adapter/BalancerAdapter.sol";
import {WrappedRateProvider} from "../../src/balancer-adapter/WrappedRateProvider.sol";

// run via `forge test -vv --match-test "create"`
contract BalancerAdapterTest is
    Test,
    BalancerSepoliaAddresses,
    ChainLinkFeedAddresses
{
    IEVC _evc_;

    Fiat USDC;
    Fiat eUSD;
    Fiat DAI;

    BalancerAdapter balancerAdapter;

    ICSPFactory cspFactory;
    IBalancerVaultGeneral balancerVault;

    uint256 constant MAX_VAL = type(uint).max;

    // we use this to track all deposits for stables (with 18 decimals)
    // it provides a benchmark for USD deposit value
    uint256 APPROX_PRICE_TRACKER;

    function setUp() public {
        vm.createSelectFork({
            blockNumber: 5_388_756,
            urlOrAlias: "https://rpc.ankr.com/eth_sepolia"
        });

        // stablecoins creation, they already mint to the caller
        USDC = new Fiat("USDC", "USD Coin", 6);
        console.log("USDC", address(USDC));
        eUSD = new Fiat("eUSD", "Euler Vault Dollars", 18);
        console.log("eUSD", address(eUSD));
        DAI = new Fiat("DAI", "DAI Stablecoin", 18);
        console.log("DAI", address(DAI));

        // balancer contracts
        cspFactory = ICSPFactory(CSP_FACTORY);
        balancerVault = IBalancerVaultGeneral(BALANCER_VAULT);
        balancerAdapter = new BalancerAdapter(CSP_FACTORY, BALANCER_VAULT);
        console.log("adapter", address(balancerAdapter));

        balancerVault.setRelayerApproval(
            address(this), // address sender,
            address(balancerAdapter), // address relayer,
            true // bool approved
        );
    }

    function test_adapter_create_cs_pool() public {
        create();
        console.log(balancerAdapter.pool());
    }

    function test_adapter_init_cs_pool() public {
        create();
        console.log(balancerAdapter.pool());
        init();
    }

    function test_adapter_join_cs_pool() public {
        create();
        init();
        address pool = balancerAdapter.pool();
        uint balance = IERC20(pool).balanceOf(address(this));
        // deposit balances to pool
        joinPool();

        balance = IERC20(pool).balanceOf(address(this)) - balance;
        console.log("balance received", balance);
        // we assert that enough BPTs were minted
        assert(balance >= 3119.0e18);
    }

    function test_adapter_pricing() public {
        create();
        init();
        address pool = balancerAdapter.pool();
        // deposit balances to pool
        joinPool();

        // this is the total supply
        uint balance = IERC20(pool).balanceOf(address(this));
        uint256 price = balancerAdapter.getPrice();

        console.log("price in USD", price);

        address quoteAsset = address(USDC);
        uint256 quoteAll = balancerAdapter.getQuote(
            balance,
            address(0),
            quoteAsset
        );

        assertApproxEqAbs(
            quoteAll * 1e12,
            APPROX_PRICE_TRACKER,
            (APPROX_PRICE_TRACKER * 1) / 100 // allow 5% deviation
        );
        uint256 halfBalance = balance / 2;
        uint256 quote = balancerAdapter.getQuote(
            halfBalance,
            address(0),
            quoteAsset
        );
        console.log("quote in USDC", quote);

        quoteAsset = address(DAI);
        quoteAll = balancerAdapter.getQuote(balance, address(0), quoteAsset);

        assertApproxEqAbs(
            quoteAll,
            APPROX_PRICE_TRACKER,
            (APPROX_PRICE_TRACKER * 1) / 100 // allow 5% deviation
        );

        console.log("quoteAll in DAI", quoteAll);
        halfBalance = balance / 2;
        quote = balancerAdapter.getQuote(halfBalance, address(0), quoteAsset);
        console.log("quote in DAI", quote);
    }

    function joinPool() internal {
        uint[] memory amounts = new uint256[](3);
        address adapter = address(balancerAdapter);

        uint eusdAmount = 1_200.0e18;
        APPROX_PRICE_TRACKER += eusdAmount;
        amounts[0] = eusdAmount;
        eUSD.transfer(adapter, eusdAmount);

        uint usdcAmount = 1_020.0e6;
        APPROX_PRICE_TRACKER += usdcAmount * 1e12;
        amounts[1] = usdcAmount;
        USDC.transfer(adapter, usdcAmount);

        uint daiAmount = 900.0e18;
        APPROX_PRICE_TRACKER += daiAmount;
        amounts[2] = daiAmount;
        DAI.transfer(adapter, daiAmount);
        console.log("join");
        // deposit balances to pool
        balancerAdapter.depositTo(amounts, address(this));
    }

    function init() private {
        uint[] memory amounts = new uint256[](4);

        address adapter = address(balancerAdapter);

        uint eusdAmount = 10.0e18;
        APPROX_PRICE_TRACKER += eusdAmount;
        amounts[1] = eusdAmount;
        eUSD.transfer(adapter, eusdAmount);

        uint usdcAmount = 10.0e6;
        APPROX_PRICE_TRACKER += usdcAmount * 1e12;
        amounts[2] = usdcAmount;
        USDC.transfer(adapter, usdcAmount);

        uint daiAmount = 10.0e18;
        APPROX_PRICE_TRACKER += daiAmount;
        amounts[3] = daiAmount;
        DAI.transfer(adapter, daiAmount);

        console.log("inititalize");
        address recipient = address(this);
        balancerAdapter.initializePool(amounts, recipient);
    }

    function create() private {
        address[] memory tokens = new address[](3);
        tokens[0] = address(eUSD);
        tokens[1] = address(USDC);
        tokens[2] = address(DAI);

        address[] memory ratePrivder = new address[](3);
        ratePrivder[0] = address(0);
        ratePrivder[1] = address(new WrappedRateProvider(USDC_FEED));
        ratePrivder[2] = address(new WrappedRateProvider(DAI_FEED));

        balancerAdapter.createPool(tokens, ratePrivder);
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
