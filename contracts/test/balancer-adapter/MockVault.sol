// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {IMinimalVault} from "../../src/balancer-adapter/interfaces/IMinimalVault.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";
import "../../lib/ethereum-vault-connector/src/utils/EVCUtil.sol";
import "forge-std/console.sol";

contract MockVault is IMinimalVault, EVCUtil {
    error Reentrancy();
    address public immutable ASSET;

    constructor(address asset, address evc) EVCUtil(IEVC(evc)) {
        ASSET = asset;
        reentrancyLock = REENTRANCY_UNLOCKED;
    }

    uint256 private constant REENTRANCY_UNLOCKED = 1;
    uint256 private constant REENTRANCY_LOCKED = 2;

    uint256 private reentrancyLock;
    bytes private snapshot;

    mapping(address => uint) public userShares;

    /// @notice Prevents reentrancy
    modifier nonReentrant() virtual {
        if (reentrancyLock != REENTRANCY_UNLOCKED) {
            revert Reentrancy();
        }

        reentrancyLock = REENTRANCY_LOCKED;

        _;

        reentrancyLock = REENTRANCY_UNLOCKED;
    }

    function deposit(
        uint256 assets,
        address receiver
    ) external override callThroughEVC nonReentrant returns (uint256) {
        address sender = EVCUtil._msgSender();
        IERC20(ASSET).transferFrom(sender, address(this), assets);
        userShares[receiver] = assets;
        return assets;
    }

    function shares(address user) external view returns (uint256) {
        return userShares[user];
    }
}
