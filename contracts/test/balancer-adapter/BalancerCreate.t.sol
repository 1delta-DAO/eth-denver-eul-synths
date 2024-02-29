// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import "evc/EthereumVaultConnector.sol";
import "../../../src/vaults/solmate/VaultSimple.sol";

// source:
// https://github.com/a16z/erc4626-tests

contract BalancerCreateTest is Test {
    IEVC _evc_;

    function setUp() public {
        vm.createSelectFork({
            blockNumber: 5_388_756,
            urlOrAlias: "https://rpc.ankr.com/eth_sepolia"
        });
    }

    // NOTE: The following test is relaxed to consider only smaller values (of type uint120),
    // since maxWithdraw() fails with large values (due to overflow).

    function test_create() public {}

    function clamp() internal pure returns (uint256) {}
}
