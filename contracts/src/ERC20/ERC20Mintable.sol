// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin/utils/ReentrancyGuard.sol";
import "openzeppelin/access/Ownable.sol";

/// @title ERC20Collateral
/// @notice It extends the ERC20 token standard to add the EVC authentication and account status checks so that the
/// token contract can be used as collateral in the EVC ecosystem.
contract ERC20Mintable is ERC20, ERC20Burnable, ReentrancyGuard, Ownable {
    constructor(
        string memory _name_,
        string memory _symbol_
    ) ERC20(_name_, _symbol_) ERC20Burnable() Ownable(msg.sender) {}

    /**
     * @dev Extension of {ERC20} that adds a set of accounts with the {OwnerRole},
     * which have permission to mint (create) new tokens as they see fit.     *
     */
    function mint(
        address account,
        uint256 amount
    ) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }
}
