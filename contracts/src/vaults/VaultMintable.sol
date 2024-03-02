// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import {VaultRegularBorrowable, ERC20} from "../helpers/vaults/open-zeppelin/VaultRegularBorrowable.sol";
import {ERC20Mintable} from "../ERC20/ERC20Mintable.sol";
import {IEVC} from "../helpers/utils/EVCClient.sol";
import {IIRM} from "../helpers/interfaces/IIRM.sol";
import {IPriceOracle} from "../helpers/interfaces/IPriceOracle.sol";

/// @title VaultMintable
/// @notice This contract extends VaultRegularBorrowable .
contract VaultMintable is VaultRegularBorrowable {
    constructor(
        IEVC _evc,
        address _asset,
        IIRM _irm,
        IPriceOracle _oracle,
        address _referenceAsset,
        string memory _name,
        string memory _symbol
    )
        VaultRegularBorrowable(
            _evc,
            ERC20Mintable(_asset),
            _irm,
            _oracle,
            ERC20(_referenceAsset),
            _name,
            _symbol
        )
    {}

    /// @notice Borrows assets.
    /// @param assets The amount of assets to borrow.
    /// @param receiver The receiver of the assets.
    function borrow(
        uint256 assets,
        address receiver
    ) external override callThroughEVC nonReentrant {
        address msgSender = _msgSenderForBorrow();

        createVaultSnapshot();

        require(assets != 0, "ZERO_ASSETS");

        // users might input an EVC subaccount, in which case we want to send tokens to the owner
        receiver = _getAccountOwner(receiver);

        _increaseOwed(msgSender, assets);

        emit Borrow(msgSender, receiver, assets);

        ERC20Mintable(asset()).mint(receiver, assets);

        requireAccountAndVaultStatusCheck(msgSender);
    }

    /// @notice Repays a debt.
    /// @dev This function burns the specified amount of assets from the caller.
    /// @param assets The amount of assets to repay.
    /// @param receiver The receiver of the repayment.
    function repay(
        uint256 assets,
        address receiver
    ) external override callThroughEVC nonReentrant {
        address msgSender = _msgSender();

        // sanity check: the receiver must be under control of the EVC. otherwise, we allowed to disable this vault as
        // the controller for an account with debt
        if (!isControllerEnabled(receiver, address(this))) {
            revert ControllerDisabled();
        }

        createVaultSnapshot();

        require(assets != 0, "ZERO_ASSETS");

        ERC20Mintable(asset()).burnFrom(msgSender, assets);

        _totalAssets += assets;

        _decreaseOwed(receiver, assets);

        emit Repay(msgSender, receiver, assets);

        requireAccountAndVaultStatusCheck(address(0));
    }
}
