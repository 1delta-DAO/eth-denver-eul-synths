// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import {VaultSimple, ERC20, IEVC} from "../helpers/vaults/open-zeppelin/VaultSimple.sol";

contract VaultCollateral is VaultSimple {
    constructor(
        IEVC _evc,
        address _asset,
        string memory _name,
        string memory _symbol
    ) VaultSimple(_evc, ERC20(_asset), _name, _symbol) {}
}