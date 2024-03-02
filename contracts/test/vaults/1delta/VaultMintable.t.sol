// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import "evc/EthereumVaultConnector.sol";
import {EVCUtil} from "evc/utils/EVCUtil.sol";
import {IRMMock} from "../../mocks/IRMMock.sol";
import {PriceOracleMock} from "../../mocks/PriceOracleMock.sol";
import {VaultMintable} from "../../../src/1delta/VaultMintable.sol";
import {VaultCollateral} from "../../../src/1delta/VaultCollateral.sol";
import {VaultRegularBorrowable} from "../../../src/vaults/open-zeppelin/VaultRegularBorrowable.sol";
import {VaultSimple} from "../../../src/vaults/open-zeppelin/VaultSimple.sol";
import {ERC20Mintable} from "../../../src/ERC20/ERC20Mintable.sol";

contract VaultMintableTest is Test {
    IEVC evc;
    MockERC20 referenceAsset;
    ERC20Mintable liabilityAsset;
    MockERC20 collateralAsset;
    IRMMock irm;
    PriceOracleMock oracle;

    VaultCollateral collateralVault;
    VaultMintable mintableVault;

    function setUp() public {
        evc = new EthereumVaultConnector();
        referenceAsset = new MockERC20("Reference Asset", "RA", 6); // USDC
        liabilityAsset = new ERC20Mintable("Liability Asset", "LA", 6); // Mintable Token
        collateralAsset = new MockERC20("Collateral Asset", "CA1", 18); // Balancer Pool Token
        irm = new IRMMock();
        oracle = new PriceOracleMock();
        
        mintableVault = new VaultMintable(evc, address(liabilityAsset), irm, oracle, address(referenceAsset), "Pool Token Liability Vault", "PTLV");

        collateralVault = new VaultCollateral(evc, address(collateralAsset), "Pool Token Collateral Vault", "PTCV");

        irm.setInterestRate(10); // 10% APY

        oracle.setResolvedAsset(address(mintableVault));
        oracle.setResolvedAsset(address(collateralVault));
        oracle.setPrice(address(liabilityAsset), address(referenceAsset), 1e6); // 1 LA = 1 RA
        oracle.setPrice(address(collateralAsset), address(referenceAsset), 3e6); // 1 CA1 = 3 RA
    }

    function mintAndApprove(address alice, address bob) public {
        liabilityAsset.mint(alice, 200e6);
        collateralAsset.mint(alice, 200e18);
        collateralAsset.mint(bob, 100e18);
        assertEq(collateralAsset.balanceOf(alice), 200e18);
        assertEq(collateralAsset.balanceOf(bob), 100e18);

        vm.prank(alice);
        liabilityAsset.approve(address(mintableVault), type(uint256).max);

        vm.prank(alice);
        collateralAsset.approve(address(collateralVault), type(uint256).max);

        vm.prank(bob);
        collateralAsset.approve(address(collateralVault), type(uint256).max);

        liabilityAsset.transferOwnership(address(mintableVault));
    }

    function test_RegularBorrowRepay(address alice, address bob) public {
        vm.assume(alice != address(0) && bob != address(0) && !evc.haveCommonOwner(alice, bob));
        vm.assume(
            alice != address(evc) && alice != address(mintableVault) && alice != address(collateralVault)
        );
        vm.assume(
            bob != address(evc) && bob != address(mintableVault) && bob != address(collateralVault)
        );

        mintAndApprove(alice, bob);

        mintableVault.setCollateralFactor(address(mintableVault), 0); // cf = 1, self-collateralization
        mintableVault.setCollateralFactor(address(collateralVault), 100); // cf = 1

        // alice deposits 50 LA
        vm.prank(alice);
        collateralVault.deposit(50e18, alice);
        assertEq(collateralAsset.balanceOf(alice), 150e18);
        assertEq(collateralVault.maxWithdraw(alice), 50e18);

        // bob deposits 100 CA1 which lets him borrow 10 LA
        vm.prank(bob);
        collateralVault.deposit(100e18, bob);
        assertEq(collateralAsset.balanceOf(bob), 0);
        assertEq(collateralVault.maxWithdraw(bob), 100e18);

        // controller and collateral not enabled, hence borrow unsuccessful
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(EVCUtil.ControllerDisabled.selector));
        mintableVault.borrow(300e6, bob);

        vm.prank(bob);
        evc.enableController(bob, address(mintableVault));

        // collateral still not enabled, hence borrow unsuccessful
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(VaultRegularBorrowable.AccountUnhealthy.selector));
        mintableVault.borrow(300e6, bob);
        vm.prank(bob);
        evc.enableCollateral(bob, address(collateralVault));

        // too much borrowed, hence borrow unsuccessful
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(VaultRegularBorrowable.AccountUnhealthy.selector));
        mintableVault.borrow(301e6, bob);

        // finally borrow is successful
        vm.prank(bob);
        mintableVault.borrow(300e6, bob);
        assertEq(liabilityAsset.balanceOf(bob), 300e6);
        assertEq(mintableVault.debtOf(bob), 300e6);
        assertEq(collateralVault.maxWithdraw(bob), 100e18); // this should return 0 but need to check

        // jump one year ahead, bob's liability increased by 10% APY.
        // his account is no longer healthy
        vm.warp(block.timestamp + 365 days);
        assertEq(liabilityAsset.balanceOf(bob), 300e6);
        assertApproxEqRel(mintableVault.debtOf(bob), 330e6, 0.01e18);
        vm.expectRevert(abi.encodeWithSelector(VaultRegularBorrowable.AccountUnhealthy.selector));
        evc.requireAccountStatusCheck(bob);

        // bob repays only some of his debt, his account is still unhealthy
        vm.prank(bob);
        liabilityAsset.approve(address(mintableVault), type(uint256).max);

        vm.prank(bob);
        uint256 repayAmount = 21e6;
        mintableVault.repay(repayAmount, bob);
        assertEq(liabilityAsset.balanceOf(bob), 300e6 - repayAmount);
        assertApproxEqRel(mintableVault.debtOf(bob), 330e6 - repayAmount, 0.01e18);
        vm.expectRevert(abi.encodeWithSelector(VaultRegularBorrowable.AccountUnhealthy.selector));
        evc.requireAccountStatusCheck(bob);

        // alice kicks in to liquidate bob. first enable controller and collateral
        vm.prank(alice);
        evc.enableController(alice, address(mintableVault));

        vm.prank(alice);
        evc.enableCollateral(alice, address(collateralVault));

        // liquidation fails as alice tries to liquidate too much
        vm.prank(alice);
        vm.expectRevert(VaultRegularBorrowable.RepayAssetsExceeded.selector);
        mintableVault.liquidate(bob, address(collateralVault), 332e6 - repayAmount);

        // finally liquidation is successful
        uint256 liquidationAmount = 5e6;
        vm.prank(alice);
        mintableVault.liquidate(bob, address(collateralVault), liquidationAmount);

        uint256 bobsCollateral = liquidationAmount * 1e12 / 3 * 120 / 100; // + 20% for liquidation reward
        assertEq(liabilityAsset.balanceOf(bob), 300e6 - repayAmount); // bob's LA balance stays unchanged
        assertApproxEqRel(mintableVault.debtOf(bob), 330e6 - repayAmount - liquidationAmount, 0.01e18); // bob's debt decreased by 5 LA due to liquidation
        assertApproxEqRel(collateralVault.maxWithdraw(bob), 100e18 -  bobsCollateral, 0.01e18); // bob's CA1 deposit stays unchanged
            // liquidation
        assertEq(mintableVault.debtOf(alice), liquidationAmount); // alices's debt increased to 5 LA due to liquidation (she took on
            // bob's debt)
        assertApproxEqRel(collateralVault.maxWithdraw(alice), 50e18 + bobsCollateral,  0.01e18); // alices's CA1 deposit stays unchanged
            // liquidation (she took on bob's collateral)
                    /*

        evc.requireAccountStatusCheck(alice);
        evc.requireAccountStatusCheck(bob);

        // alice repays her debt taken on from bob
        vm.prank(alice);
        mintableVault.repay(6e18, alice);
        assertEq(liabilityAsset.balanceOf(alice), 50e18 - 6e18);
        assertEq(mintableVault.debtOf(alice), 0);

        // she disables collaterals and controller
        vm.prank(alice);
        mintableVault.disableController();

        vm.prank(alice);
        evc.disableCollateral(alice, address(mintableVault));

        vm.prank(alice);
        evc.disableCollateral(alice, address(collateralVault));

        vm.prank(alice);

        // then alice withdraws the collateral seized
        vm.prank(alice);

        // bob repays the rest of his debt
        vm.prank(bob);
        mintableVault.repay(30e18, bob);
        assertEq(liabilityAsset.balanceOf(bob), 35e18 - 2.680982126514837396e18 - 30e18);
        assertEq(mintableVault.debtOf(bob), 0);

        // he disables collaterals and controller
        vm.prank(bob);
        mintableVault.disableController();

        vm.prank(bob);
        evc.disableCollateral(bob, address(collateralVault));

        // finally, bob withdraws his collaterals
        vm.prank(bob);
        collateralVault.withdraw(100e18, bob, bob);
        assertEq(collateralAsset.balanceOf(bob), 100e18);
        assertEq(collateralVault.maxWithdraw(bob), 0);

        // alice withdraws her LA deposit, account for rounding
        vm.prank(alice);
        mintableVault.withdraw(50e18 - 35e18 + 2.680982126514837396e18 + 6e18 + 30e18 - 1, alice, alice);
        assertEq(liabilityAsset.balanceOf(alice), 100e18 - 35e18 + 2.680982126514837396e18 + 30e18 - 1);
        assertEq(mintableVault.maxWithdraw(alice), 0);

        // final checks
        assertEq(liabilityAsset.balanceOf(address(mintableVault)), 1);
        assertEq(liabilityAsset.balanceOf(address(alice)), 100e18 - 35e18 + 2.680982126514837396e18 + 30e18 - 1);
        assertEq(liabilityAsset.balanceOf(address(bob)), 35e18 - 2.680982126514837396e18 - 30e18);
        assertEq(mintableVault.maxWithdraw(alice), 0);
        assertEq(mintableVault.maxWithdraw(bob), 0);
        assertEq(mintableVault.debtOf(alice), 0);
        assertEq(mintableVault.debtOf(bob), 0);

        assertEq(collateralAsset.balanceOf(address(collateralVault)), 0);
        assertEq(collateralAsset.balanceOf(address(alice)), 0);
        assertEq(collateralAsset.balanceOf(address(bob)), 100e18);
        assertEq(collateralVault.maxWithdraw(alice), 0);
        assertEq(collateralVault.maxWithdraw(bob), 0); */
    }

    /* function test_RegularBorrowRepayWithBatch(address alice, address bob) public {
        vm.assume(alice != address(0) && bob != address(0) && !evc.haveCommonOwner(alice, bob));
        vm.assume(
            alice != address(evc) && alice != address(mintableVault) && alice != address(collateralVault)
        );
        vm.assume(
            bob != address(evc) && bob != address(mintableVault) && bob != address(collateralVault)
        );

        mintAndApprove(alice, bob);

        mintableVault.setCollateralFactor(address(mintableVault), 100); // cf = 1, self-collateralization
        mintableVault.setCollateralFactor(address(collateralVault), 100); // cf = 1

        // alice deposits 50 LA
        vm.prank(alice);
        mintableVault.deposit(50e18, alice);
        assertEq(liabilityAsset.balanceOf(alice), 50e18);
        assertEq(mintableVault.maxWithdraw(alice), 50e18);

        // bob deposits collaterals, enables them, enables controller and borrows
        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](5);
        items[0] = IEVC.BatchItem({
            targetContract: address(collateralVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultSimple.deposit.selector, 100e18, bob)
        });
        items[1] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableController.selector, bob, address(mintableVault))
        });
        items[2] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableCollateral.selector, bob, address(collateralVault))
        });
        items[3] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultSimpleBorrowable.borrow.selector, 35e18 + 0.01e18, bob)
        });

        // it will revert because of the borrow amount being to high
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(VaultSimpleBorrowable.AccountUnhealthy.selector));
        evc.batch(items);

        items[4] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultSimpleBorrowable.borrow.selector, 35e18, bob)
        });

        // now it will succeed
        vm.prank(bob);
        evc.batch(items);

        assertEq(liabilityAsset.balanceOf(address(mintableVault)), 15e18);
        assertEq(liabilityAsset.balanceOf(address(alice)), 50e18);
        assertEq(liabilityAsset.balanceOf(address(bob)), 35e18);
        assertEq(mintableVault.maxWithdraw(alice), 15e18);
        assertEq(mintableVault.maxWithdraw(bob), 0);
        assertEq(mintableVault.debtOf(alice), 0);
        assertEq(mintableVault.debtOf(bob), 35e18);

        assertEq(collateralAsset.balanceOf(address(collateralVault)), 100e18);
        assertEq(collateralAsset.balanceOf(address(alice)), 0);
        assertEq(collateralAsset.balanceOf(address(bob)), 0);
        assertEq(collateralVault.maxWithdraw(alice), 0);
        assertEq(collateralVault.maxWithdraw(bob), 100e18);

        // jump one year ahead, bob's liability increased by 10% APY.
        // his account is no longer healthy
        vm.warp(block.timestamp + 365 days);
        assertEq(liabilityAsset.balanceOf(bob), 35e18);
        assertEq(mintableVault.debtOf(bob), 35e18 + 3.680982126514837396e18);
        assertEq(mintableVault.maxWithdraw(alice), 15e18);
        vm.expectRevert(abi.encodeWithSelector(VaultSimpleBorrowable.AccountUnhealthy.selector));
        evc.requireAccountStatusCheck(bob);

        // bob repays only some of his debt, his account is still unhealthy
        vm.prank(bob);
        liabilityAsset.approve(address(mintableVault), type(uint256).max);

        vm.prank(bob);
        mintableVault.repay(2.680982126514837396e18, bob);
        assertEq(liabilityAsset.balanceOf(bob), 35e18 - 2.680982126514837396e18);
        assertEq(mintableVault.debtOf(bob), 35e18 + 1e18);
        assertEq(mintableVault.maxWithdraw(alice), 15e18 + 2.680982126514837396e18);
        vm.expectRevert(abi.encodeWithSelector(VaultSimpleBorrowable.AccountUnhealthy.selector));
        evc.requireAccountStatusCheck(bob);

        // alice kicks in to liquidate bob, repay the debt and withdraw seized collateral
        items = new IEVC.BatchItem[](11);
        items[0] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableController.selector, alice, address(mintableVault))
        });
        items[1] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableCollateral.selector, alice, address(mintableVault))
        });
        items[2] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableCollateral.selector, alice, address(collateralVault))
        });
        items[3] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: alice,
            value: 0,
            data: abi.encodeWithSelector(VaultSimpleBorrowable.repay.selector, 6e18, alice)
        });
        items[4] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: alice,
            value: 0,
            data: abi.encodeWithSelector(VaultSimpleBorrowable.disableController.selector)
        });
        items[5] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.disableCollateral.selector, alice, address(mintableVault))
        });
        items[6] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.disableCollateral.selector, alice, address(collateralVault))
        });

        vm.prank(alice);
        evc.batch(items);

        assertEq(liabilityAsset.balanceOf(address(mintableVault)), 50e18 - 35e18 + 2.680982126514837396e18 + 6e18);
        assertEq(liabilityAsset.balanceOf(address(alice)), 50e18 - 6e18);
        assertEq(liabilityAsset.balanceOf(address(bob)), 35e18 - 2.680982126514837396e18);
        assertEq(mintableVault.maxWithdraw(alice), 50e18 - 35e18 + 2.680982126514837396e18 + 6e18);
        assertEq(mintableVault.maxWithdraw(bob), 0);
        assertEq(mintableVault.debtOf(alice), 0);
        assertEq(mintableVault.debtOf(bob), 30e18);

        assertEq(collateralAsset.balanceOf(address(collateralVault)), 100e18);
        assertEq(collateralAsset.balanceOf(address(alice)), 0);
        assertEq(collateralAsset.balanceOf(address(bob)), 0);
        assertEq(collateralVault.maxWithdraw(alice), 0);
        assertEq(collateralVault.maxWithdraw(bob), 100e18);

        // bob repays his debt and withdraws his collaterals
        items = new IEVC.BatchItem[](6);
        items[0] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultSimpleBorrowable.repay.selector, 30e18, bob)
        });
        items[1] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultSimpleBorrowable.disableController.selector)
        });
        items[2] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.disableCollateral.selector, bob, address(collateralVault))
        });
        items[3] = IEVC.BatchItem({
            targetContract: address(collateralVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultSimple.withdraw.selector, 100e18, bob, bob)
        });

        vm.prank(bob);
        evc.batch(items);

        // alice withdraws her LA deposit
        vm.prank(alice);
        mintableVault.withdraw(50e18 - 35e18 + 2.680982126514837396e18 + 6e18 + 30e18 - 1, alice, alice);

        // final checks
        assertEq(liabilityAsset.balanceOf(address(mintableVault)), 1);
        assertEq(liabilityAsset.balanceOf(address(alice)), 100e18 - 35e18 + 2.680982126514837396e18 + 30e18 - 1);
        assertEq(liabilityAsset.balanceOf(address(bob)), 35e18 - 2.680982126514837396e18 - 30e18);
        assertEq(mintableVault.maxWithdraw(alice), 0);
        assertEq(mintableVault.maxWithdraw(bob), 0);
        assertEq(mintableVault.debtOf(alice), 0);
        assertEq(mintableVault.debtOf(bob), 0);

        assertEq(collateralAsset.balanceOf(address(collateralVault)), 0);
        assertEq(collateralAsset.balanceOf(address(alice)), 0);
        assertEq(collateralAsset.balanceOf(address(bob)), 100e18);
        assertEq(collateralVault.maxWithdraw(alice), 0);
        assertEq(collateralVault.maxWithdraw(bob), 0);
    } */

    function test_LeveragePositionWithBatch(address alice, address bob) public {
        vm.assume(alice != address(0) && bob != address(0) && !evc.haveCommonOwner(alice, bob));
        vm.assume(
            alice != address(evc) && alice != address(mintableVault) && alice != address(collateralVault)
        );
        vm.assume(
            bob != address(evc) && bob != address(mintableVault) && bob != address(collateralVault)
        );

        mintAndApprove(alice, bob);

        mintableVault.setCollateralFactor(address(mintableVault), 0); // cf = 1, self-collateralization
        mintableVault.setCollateralFactor(address(collateralVault), 80); // cf = 1

        uint256 borrowAmount = 100e6;
        uint256 depositAmount = 50e18;

        // bob deposits collaterals, enables them, enables controller and borrows
        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](4);
        items[0] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableController.selector, bob, address(mintableVault))
        });
        items[1] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(IEVC.enableCollateral.selector, bob, address(collateralVault))
        });
        items[2] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultMintable.borrow.selector, borrowAmount, bob)
        });
        items[3] = IEVC.BatchItem({
            targetContract: address(collateralVault),
            onBehalfOfAccount: bob,
            value: 0,
            data: abi.encodeWithSelector(VaultSimple.deposit.selector, depositAmount, bob)
        });

        vm.prank(bob);
        evc.batch(items);

        assertEq(liabilityAsset.balanceOf(address(mintableVault)), 0);
        assertEq(liabilityAsset.balanceOf(address(bob)), borrowAmount);
        assertEq(mintableVault.maxWithdraw(bob), 0);
        assertEq(mintableVault.debtOf(bob), borrowAmount);

        assertEq(collateralAsset.balanceOf(address(collateralVault)), depositAmount);
        assertEq(collateralAsset.balanceOf(address(bob)), 100e18 - depositAmount);
        assertEq(collateralVault.maxWithdraw(bob), depositAmount);
    }
}
