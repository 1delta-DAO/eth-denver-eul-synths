// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {ICSPFactory} from "../../src/balancer-adapter/interfaces/ICSPFactory.sol";
import {IBalancerVaultGeneral} from "../../src/balancer-adapter/interfaces/IVaultGeneral.sol";
import {IERC20} from "../../src/balancer-adapter/interfaces/IERC20.sol";
import {IBalancerPool} from "../../src/balancer-adapter/interfaces/IBalancerPool.sol";
import {BalancerAdapter} from "../../src/balancer-adapter/BalancerAdapter.sol";
import {WrappedRateProvider} from "../../src/balancer-adapter/WrappedRateProvider.sol";

import "evc/EthereumVaultConnector.sol";
import {VaultMintable} from "../../src/1delta/VaultMintable.sol";
import {VaultCollateral} from "../../src/1delta/VaultCollateral.sol";
import {ERC20Mintable} from "../../src/ERC20/ERC20Mintable.sol";
import {IRMMock} from "../../test/mocks/IRMMock.sol";
import {BalancerSepoliaAddresses} from "../../test/balancer-adapter/BalancerSepoliaAddresses.sol";
import {ChainLinkFeedAddresses} from "../../test/balancer-adapter/ChainLinkFeedAddresses.sol";

// run via `forge test -vv

contract DeployEulSuynths is BalancerSepoliaAddresses, ChainLinkFeedAddresses {
    ERC20Mintable USDC;
    ERC20Mintable eUSD;
    ERC20Mintable DAI;
    IBalancerPool poolToken;

    BalancerAdapter balancerAdapter;

    IEVC evc;

    VaultCollateral collateralVault;
    VaultMintable mintableVault;

    uint256 constant MAX_VAL = type(uint).max;

    constructor() {
        // stablecoins creation, they already mint to the caller
        USDC = new ERC20Mintable("USDC", "USD Coin", 6);
        console.log("USDC", address(USDC));
        eUSD = new ERC20Mintable("eUSD", "Euler Vault Dollars", 18);
        console.log("eUSD", address(eUSD));
        DAI = new ERC20Mintable("DAI", "DAI Stablecoin", 18);
        console.log("DAI", address(DAI));

        eUSD.mint(address(this), 1_000_000e18);

        // EVC
        evc = new EthereumVaultConnector();

        // balancer contracts
        balancerAdapter = new BalancerAdapter(
            CSP_FACTORY,
            BALANCER_VAULT,
            address(evc)
        );

        console.log("create");
        create();

        console.log("init");
        init();

        console.log("joinPool");
        joinPool();

        // vault contract
        IRMMock irm = new IRMMock();
        mintableVault = new VaultMintable(
            evc,
            address(eUSD),
            irm,
            balancerAdapter,
            address(USDC),
            "eulUSD Liability Vault",
            "EUSDLV"
        );
        collateralVault = new VaultCollateral(
            evc,
            address(poolToken),
            "Balancer Pool Token Collateral Vault",
            "BPTCV"
        );
        irm.setInterestRate(10); // 10% APY

        // transfer ownership
        eUSD.transferOwnership(address(mintableVault));
    }

    function joinPool() internal {
        uint[] memory amounts = new uint256[](3);
        address adapter = address(balancerAdapter);

        (address[] memory assets, uint[] memory scales) = balancerAdapter
            .getDecimalScalesAndTokens();

        for (uint i = 0; i < assets.length; i++) {
            uint amount = (1000.0 + i * 10) * scales[i];
            amounts[i] = amount;
            IERC20(assets[i]).transfer(adapter, amount);
        }

        // uint eusdAmount = 1_200.0e18;
        // amounts[0] = eusdAmount;
        // eUSD.transfer(adapter, eusdAmount);

        // uint usdcAmount = 1_020.0e6;
        // amounts[1] = usdcAmount;
        // USDC.transfer(adapter, usdcAmount);

        // uint daiAmount = 900.0e18;
        // amounts[2] = daiAmount;
        // DAI.transfer(adapter, daiAmount);
        console.log("join");
        // deposit balances to pool
        balancerAdapter.depositTo(amounts, address(this));
    }

    function init() private {
        uint[] memory amounts = new uint256[](4);

        address adapter = address(balancerAdapter);

        (address[] memory assets, uint[] memory scales) = balancerAdapter
            .getDecimalScalesAndTokens();

        for (uint i = 0; i < assets.length; i++) {
            uint amount = (1000.0 + i * 10) * scales[i];
            amounts[i] = amount;
            IERC20(assets[i]).transfer(adapter, amount);
        }

        console.log("inititalize");
        address recipient = address(this);
        balancerAdapter.initializePool(amounts, recipient);

        poolToken = IBalancerPool(balancerAdapter.pool());
        console.log("poolToken", address(poolToken));
    }

    function create() private {
        address[] memory tokens = new address[](3);
        tokens[0] = address(eUSD);
        tokens[1] = address(USDC);
        tokens[2] = address(DAI);

        address[] memory ratePrivder = new address[](3);
        ratePrivder[0] = address(0);
        ratePrivder[1] = address(new WrappedRateProvider(USDC_FEED));
        ratePrivder[2] = address(new WrappedRateProvider(DAI_FEED));

        balancerAdapter.createPool(tokens, ratePrivder);
    }
}
