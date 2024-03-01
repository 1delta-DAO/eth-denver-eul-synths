// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {IMinimalVault} from "../../src/balancer-adapter/interfaces/IMinimalVault.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";

contract MockVault is IMinimalVault {
    address immutable ASSET;

    constructor(address asset) {
        ASSET = asset;
    }

    function deposit(
        uint256 assets,
        address receiver
    ) external override returns (uint256 shares) {
        IERC20(ASSET).transferFrom(msg.sender, receiver, assets);
        return assets;
    }
}
