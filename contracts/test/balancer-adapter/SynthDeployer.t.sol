// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {ICSPFactory, IRateProvider} from "../../src/balancer-adapter/interfaces/ICSPFactory.sol";
import {IBalancerVaultGeneral, JoinPoolRequest, SingleSwap, SwapKind, FundManagement} from "../../src/balancer-adapter/interfaces/IVaultGeneral.sol";
import {Fiat} from "../ERC20/Fiat.sol";
import "evc/EthereumVaultConnector.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";
import {IBalancerPool} from "../../src/balancer-adapter/interfaces/IBalancerPool.sol";
import {StablePoolUserData} from "../../src/balancer-adapter/interfaces/StablePoolUserData.sol";
import {BalancerAdapter, IMinimalVault} from "../../src/balancer-adapter/BalancerAdapter.sol";
import {WrappedRateProvider} from "../../src/balancer-adapter/WrappedRateProvider.sol";
import {MockVault} from "./MockVault.sol";
import {EulSynths} from "../../src/deployer/Deployer.sol";

// run via `forge test -vv --match-test "create"`
contract SynthDeployerTest is Test {
    EulSynths synths;

    function setUp() public {
        vm.createSelectFork({
            blockNumber: 5_388_756,
            urlOrAlias: "https://eth-sepolia.public.blastapi.io"
        });

        synths = new EulSynths();
    }

    function test_nothing() external {
        console.log("hi");
    }
}
