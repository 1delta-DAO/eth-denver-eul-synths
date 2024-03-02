// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {ICSPFactory} from "../../src/balancer-adapter/interfaces/ICSPFactory.sol";
import {IBalancerVaultGeneral} from "../../src/balancer-adapter/interfaces/IVaultGeneral.sol";
import {BalancerSepoliaAddresses} from "../balancer-adapter/BalancerSepoliaAddresses.sol";
import {ChainLinkFeedAddresses} from "../balancer-adapter/ChainLinkFeedAddresses.sol";
import {Fiat} from "../ERC20/Fiat.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";
import {IBalancerPool} from "../../src/balancer-adapter/interfaces/IBalancerPool.sol";
import {BalancerAdapter} from "../../src/balancer-adapter/BalancerAdapter.sol";
import {WrappedRateProvider} from "../../src/balancer-adapter/WrappedRateProvider.sol";

import "evc/EthereumVaultConnector.sol";
import {VaultMintable} from "../../src/1delta/VaultMintable.sol";
import {VaultCollateral} from "../../src/1delta/VaultCollateral.sol";
import {ERC20Mintable} from "../../src/ERC20/ERC20Mintable.sol";
import {IRMMock} from "../mocks/IRMMock.sol";

// run via `forge test -vv --match-test "create"`
contract BalancerAdapterVaultTest is
    Test,
    BalancerSepoliaAddresses,
    ChainLinkFeedAddresses
{
    Fiat USDC;
    ERC20Mintable eUSD;
    Fiat DAI;
    IBalancerPool poolToken;

    BalancerAdapter balancerAdapter;

    IEVC evc;

    VaultCollateral collateralVault;
    VaultMintable mintableVault;

    uint256 constant MAX_VAL = type(uint).max;

    // we use this to track all deposits for stables (with 18 decimals)
    // it provides a benchmark for USD deposit value
    uint256 APPROX_PRICE_TRACKER;

    function setUp() public {
        vm.createSelectFork({
            blockNumber: 5_388_756,
            urlOrAlias: "https://eth-sepolia.public.blastapi.io"
        });

        // stablecoins creation, they already mint to the caller
        USDC = new Fiat("USDC", "USD Coin", 6);
        console.log("USDC", address(USDC));
        eUSD = new ERC20Mintable("eUSD", "Euler Vault Dollars", 18);
        console.log("eUSD", address(eUSD));
        DAI = new Fiat("DAI", "DAI Stablecoin", 18);
        console.log("DAI", address(DAI));

        eUSD.mint(address(this), 1_000_000e18);

        // EVC
        evc = new EthereumVaultConnector(); 

        // balancer contracts
        balancerAdapter = new BalancerAdapter(
            CSP_FACTORY,
            BALANCER_VAULT,
            address(evc)
        );

        console.log("create");
        create();

        console.log("init");
        init();

        console.log("joinPool");
        joinPool();

        // vault contract
        IRMMock irm = new IRMMock();
        mintableVault = new VaultMintable(evc, address(eUSD), irm, balancerAdapter, address(USDC), "eUSD Liability Vault", "EUSDLV");
        collateralVault = new VaultCollateral(evc, address(poolToken), "Pool Token Collateral Vault", "PTCV");
        irm.setInterestRate(10); // 10% APY

        // transfer ownership
        eUSD.transferOwnership(address(mintableVault));
    }

    function test_adapter_vault(address alice) public {
        address caller = alice;

        console.log("assume");
        vm.assume(caller != address(0));
        vm.assume(
            caller != address(evc) && caller != address(mintableVault) && caller != address(collateralVault)
        );

        USDC.transfer(caller, 200e6);
        assertEq(USDC.balanceOf(caller), 200e6);

        console.log("setCollateralFactor");
        mintableVault.setCollateralFactor(address(mintableVault), 0); // cf = 0, self-collateralization
        mintableVault.setCollateralFactor(address(collateralVault), 80); // cf = 0.8

        uint256 borrowAmount = 20e18; // poolToken

        address depositAsset = address(USDC);
        uint256 depositAmount = 50e6;

        address vault = address(collateralVault);
        address recipient = caller;

        console.log("create batch");
        // deposits collaterals, enables them, enables controller and borrows
        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](4);
        items[0] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableController.selector, caller, address(mintableVault))
        });
        items[1] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableCollateral.selector, caller, address(collateralVault))
        });
        items[2] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: caller,
            value: 0,
            data: abi.encodeWithSelector(VaultMintable.borrow.selector, borrowAmount, address(balancerAdapter))
        });
        items[3] = IEVC.BatchItem({
            targetContract: address(balancerAdapter),
            onBehalfOfAccount: caller,
            value: 0,
            data: abi.encodeWithSelector(
                BalancerAdapter.facilitateLeveragedDeposit.selector,
                depositAsset,
                depositAmount,
                vault,
                recipient
            )
        });

        console.log("approve collateral"); 
        vm.prank(caller);
        USDC.approve(address(balancerAdapter), type(uint).max);

        console.log("batch");
        evc.batch(items);
        vm.stopPrank();

        assertEq(eUSD.balanceOf(address(mintableVault)), 0);
        assertEq(eUSD.balanceOf(caller), borrowAmount);
        assertEq(mintableVault.maxWithdraw(caller), 0);
        assertEq(mintableVault.debtOf(caller), borrowAmount);

        assertEq(poolToken.balanceOf(address(collateralVault)), depositAmount);
        assertEq(poolToken.balanceOf(caller), 100e18 - depositAmount);
        assertEq(collateralVault.maxWithdraw(caller), depositAmount);
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

        poolToken = IBalancerPool(balancerAdapter.pool());
        console.log("poolToken", address(poolToken));
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
}
