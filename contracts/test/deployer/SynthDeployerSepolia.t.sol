// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";
import {BalancerAdapter} from "../../src/balancer-adapter/BalancerAdapter.sol";
import {EulSynths, VaultMintable, VaultCollateral, IEVC, ERC20Mintable} from "../../src/deployer/Deployer.sol";
import {BalancerAdapterSepolia} from "../../src/balancer-adapter/BalancerAdapterSepolia.sol";
import "evc/EthereumVaultConnector.sol";

// forge test -vv --match-contract "SynthDeployerTestSepolia"
contract SynthDeployerTestSepolia is Test {
    EulSynths synths;
    EthereumVaultConnector evc;
    BalancerAdapterSepolia balancerAdapterSepolia;
    address DEPLOYED_EVC = 0xA347d56A33Ea46E8dCAF2Ce2De57087f8f171Bd6;
    address DEPLOYED_SYNTHS = 0x7D5a7B529838859e90d027C0F83Ed0789c1e0DDf;
    address DEPLOYED_ADAPTER = 0x3046ff18D6D0726BC9711E29DAE3A20F7C33de98;

    function setUp() public {
        vm.createSelectFork({
            blockNumber: 5_399_203,
            urlOrAlias: "https://rpc.notadegen.com/eth/sepolia"
        });
        evc = EthereumVaultConnector(payable(DEPLOYED_EVC));
        balancerAdapterSepolia = BalancerAdapterSepolia(DEPLOYED_ADAPTER);
        synths = EulSynths(0x7D5a7B529838859e90d027C0F83Ed0789c1e0DDf);
    }

    function test_adapter_vault() public {
        address caller = 0x19b04cCcEA74AE40940aFd19d1E60DA940668cf7;

        VaultMintable mintableVault = synths.mintableVault();
        VaultCollateral collateralVault = synths.collateralVault();

        console.log("mintableVault", address(mintableVault));
        console.log("collateralVault", address(collateralVault));

        console.log("assume");

        console.log("this", address(this));
        console.log("adapter", address(synths.balancerAdapter()));
        console.log("evc", address(synths.evc()));

        vm.assume(caller != address(0));
        vm.assume(
            caller != address(evc) &&
                caller != address(mintableVault) &&
                caller != address(collateralVault)
        );
        ERC20Mintable DAI = synths.DAI();

        // faucet and transfer
        synths.faucet(address(DAI));
        DAI.transfer(caller, 200e18);
        assertEq(DAI.balanceOf(caller), 200e18);

        uint256 borrowAmount = 20e18; // eUSD

        address depositAsset = address(DAI);
        uint256 depositAmount = 50e18;

        address vault = address(collateralVault);
        address recipient = caller;

        address balancerAdapter = address(synths.balancerAdapter());

        console.log("create batch");
        // deposits collaterals, enables them, enables controller and borrows
        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](4);
        items[0] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(
                IEVC.enableController.selector,
                caller,
                address(mintableVault)
            )
        });
        items[1] = IEVC.BatchItem({
            targetContract: address(evc),
            onBehalfOfAccount: address(0),
            value: 0,
            data: abi.encodeWithSelector(
                IEVC.enableCollateral.selector,
                caller,
                address(collateralVault)
            )
        });
        items[2] = IEVC.BatchItem({
            targetContract: address(mintableVault),
            onBehalfOfAccount: caller,
            value: 0,
            data: abi.encodeWithSelector(
                VaultMintable.borrow.selector,
                borrowAmount,
                balancerAdapter
            )
        });
        items[3] = IEVC.BatchItem({
            targetContract: balancerAdapter,
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
        DAI.approve(balancerAdapter, type(uint).max);

        console.log("batch");
        vm.prank(caller);
        evc.batch(items);

        ERC20Mintable eulUSD = synths.eulUSD();
        assertEq(eulUSD.balanceOf(address(mintableVault)), 0);
        assertEq(eulUSD.balanceOf(caller), 0);
        assertEq(mintableVault.maxWithdraw(caller), 0);
        assertEq(mintableVault.debtOf(caller), borrowAmount);
        assertEq(synths.poolToken().balanceOf(caller), 0);

        uint collateralBalance = synths.poolToken().balanceOf(
            address(collateralVault)
        );
        uint256 poolTokenAmountInUSDC = synths.balancerAdapter().getQuote(
            collateralBalance,
            address(0),
            address(DAI)
        );
        uint256 usdAmountDepositAndBorrow = (borrowAmount +
            depositAmount *
            10 ** (eulUSD.decimals() - IERC20(depositAsset).decimals())) /
            10 ** (eulUSD.decimals() - DAI.decimals());
        assertApproxEqRel(
            poolTokenAmountInUSDC,
            usdAmountDepositAndBorrow,
            0.01e18
        );
    }
}
