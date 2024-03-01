// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import "./IERC20.sol";

interface IBalancerPool is IERC20 {
    /**
     * @dev Returns this Pool's ID, used when interacting with the Vault (to e.g. join the Pool or swap with it).
     */
    function getPoolId() external view returns (bytes32);

    function getScalingFactors() external view returns (uint256[] memory);

    function getRateProviders() external view returns (address[] memory);

    function getActualSupply() external view returns (uint256);
}
