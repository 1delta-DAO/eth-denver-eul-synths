// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin/utils/ReentrancyGuard.sol";
import "openzeppelin/access/Ownable.sol";

/// @title ERC20Collateral
/// @notice It extends the ERC20 token standard to add the EVC authentication and account status checks so that the
/// token contract can be used as collateral in the EVC ecosystem.
contract ERC20Mintable is ERC20, Ownable {
    uint8 private decimal;

    constructor(
        string memory _name_,
        string memory _symbol_,
        uint8 _decimal
    ) ERC20(_name_, _symbol_) Ownable(msg.sender) {
        decimal = _decimal;
    }

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

    function burn(address from, uint256 value) public onlyOwner {
        _burn(from, value);
    }

    function burnFrom(address account, uint256 value) public onlyOwner {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }

    function decimals() public view override returns (uint8) {
        return decimal;
    }
}
