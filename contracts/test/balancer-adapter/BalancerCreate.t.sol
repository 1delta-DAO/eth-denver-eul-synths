// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "evc/EthereumVaultConnector.sol";
import "../../src/vaults/solmate/VaultSimple.sol";
import {ICSPFactory} from "../../src/balancer-adapter/interfaces/ICSPFactory.sol";
import {IBalancerVault} from "../../src/balancer-adapter/interfaces/IVault.sol";
import {BalancerSepoliaAddresses} from "./balancerSepoliaAddresses.sol";
import {Fiat} from "../ERC20/Fiat.sol";

// run via `forge test -vv --match-test "create"`
contract BalancerCreateTest is Test, BalancerSepoliaAddresses {
    IEVC _evc_;

    Fiat USDC;
    Fiat USDT;
    Fiat DAI;

    ICSPFactory cspFactory;
    IBalancerVault balancerVault;

    function setUp() public {
        vm.createSelectFork({
            blockNumber: 5_388_756,
            urlOrAlias: "https://rpc.ankr.com/eth_sepolia"
        });
        USDC = new Fiat("USDC", "USD Coin", 6);
        USDT = new Fiat("USDT", "Tether", 6);
        DAI = new Fiat("DAI", "DAI  Stablecoin", 18);
        cspFactory = ICSPFactory(CSP_FACTORY);
        balancerVault = IBalancerVault(BALANCER_VAULT);
    }

    // NOTE: The following test is relaxed to consider only smaller values (of type uint120),
    // since maxWithdraw() fails with large values (due to overflow).

    function test_create_pool() public {

    }

    function clamp() internal pure returns (uint256) {}
}
