// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {ICSPFactoryGeneral} from "./interfaces/ICSPFactory.sol";
import {IBalancerVaultGeneral, JoinPoolRequest, SingleSwap, SwapKind, FundManagement} from "./interfaces/IVaultGeneral.sol";
import {StablePoolUserData} from "./interfaces/StablePoolUserData.sol";
import {IBalancerPool} from "./interfaces/IBalancerPool.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract BalancerAdapter {
    address public pool;
    bytes32 public poolId;

    address public immutable cspFactory;
    address public immutable balancerVault;
    address[] pooledTokens;

    constructor(address _cspFactory, address _balancerVault) {
        cspFactory = _cspFactory;
        balancerVault = _balancerVault;
    }

    function createPool(
        address[] memory tokens,
        address[] memory rateProviders
    ) external {
        require(pool == address(0), "Pool already deployed");
        {
            uint256[] memory tokenRateCacheDurations = new uint256[](3);
            uint256 amplificationParameter = 2000;
            uint256 swapFeePercentage = 0.0003e18; // 3 bp fee
            bool exemptFromYieldProtocolFeeFlag = true;
            address owner = address(this);
            pool = ICSPFactoryGeneral(cspFactory).create(
                "3eUSD", // string memory name,
                "3 Euler Bootstrapped USD Pool", // string memory symbol,
                tokens, // IERC20[] memory tokens,
                amplificationParameter, // uint256 amplificationParameter,
                rateProviders, // IRateProvider[] memory rateProviders,
                tokenRateCacheDurations, // uint256[] memory tokenRateCacheDurations,
                exemptFromYieldProtocolFeeFlag, // bool exemptFromYieldProtocolFeeFlag,
                swapFeePercentage, // uint256 swapFeePercentage,
                owner, // address owner,
                0x0 // bytes32 salt
            );
            poolId = IBalancerPool(pool).getPoolId();

            // approve vault for future txns
            address vault = balancerVault;
            for (uint i; i < tokens.length; ) {
                IERC20(tokens[i]).approve(vault, type(uint).max);
                unchecked {
                    i++;
                }
            }
        }
    }

    /**
     * Initialize the Balancer pool
     * @param amounts amounts to be deposited in order, padded with pool token
     */
    function initializePool(
        uint256[] memory amounts,
        address recipient
    ) external {
        /**
         *  Balancer CSPs add the pool token to the registered tokens
         *  The token might be added in the middle
         */
        (address[] memory tokens, , ) = IBalancerVaultGeneral(balancerVault)
            .getPoolTokens(poolId);
        pooledTokens = tokens;
        // check the order of the tokens

        bytes memory userData = abi.encode(
            StablePoolUserData.JoinKind.INIT,
            // these are the balances to be drawn
            amounts, //   createArr4(10.0e18, 0, 10.0e6, 10.0e18), // index 1 is the BPT
            uint256(0) // not used for init
        );
        JoinPoolRequest memory request = JoinPoolRequest(
            tokens, // IAsset[] assets;
            fillWith(type(uint).max, 4), // uint256[] maxAmountsIn;
            userData, // bytes userData;
            false // bool fromInternalBalance;
        );

        IBalancerVaultGeneral(balancerVault).joinPool(
            poolId, // bytes32 poolId,
            address(this), // address sender,
            recipient, // address recipient,
            request // JoinPoolRequest memory request
        );
    }

    function depositTo(uint256[] memory amounts, address recipient) external {
        bytes memory userData = abi.encode(
            StablePoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            // these are the balances to be drawn
            amounts,
            uint256(0)
        );
        JoinPoolRequest memory request = JoinPoolRequest(
            pooledTokens, // IAsset[] assets;
            fillWith(type(uint).max, 4), // uint256[] maxAmountsIn;
            userData, // bytes userData;
            false // bool fromInternalBalance;
        );

        // regular join and NO init
        IBalancerVaultGeneral(balancerVault).joinPool(
            poolId, // bytes32 poolId,
            address(this), // address sender,
            recipient, // address recipient,
            request // JoinPoolRequest memory request
        );
    }

    function createArr4(
        uint256 value0,
        uint256 value1,
        uint256 value2,
        uint256 value3
    ) internal pure returns (uint256[] memory target) {
        target = new uint256[](4);
        target[0] = value0;
        target[1] = value1;
        target[2] = value2;
        target[3] = value3;
    }

    // create same value array
    function fillWith(
        uint256 value,
        uint length
    ) internal pure returns (uint256[] memory target) {
        target = new uint256[](length);
        for (uint i; i < length; i++) {
            target[i] = value;
        }
    }
}
