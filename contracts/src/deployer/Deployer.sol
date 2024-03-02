// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {ICSPFactory} from "../balancer-adapter/interfaces/ICSPFactory.sol";
import {IBalancerVaultGeneral} from "../balancer-adapter/interfaces/IVaultGeneral.sol";
import {IERC20} from "../balancer-adapter/interfaces/IERC20.sol";
import {IBalancerPool} from "../balancer-adapter/interfaces/IBalancerPool.sol";
import {BalancerAdapter} from "../balancer-adapter/BalancerAdapter.sol";
import {WrappedRateProvider} from "../balancer-adapter/WrappedRateProvider.sol";

import "evc/EthereumVaultConnector.sol";
import {VaultMintable} from "../vaults/VaultMintable.sol";
import {VaultCollateral} from "../vaults/VaultCollateral.sol";
import {ERC20Mintable} from "../ERC20/ERC20Mintable.sol";
import {IRMMock} from "../../test/mocks/IRMMock.sol";
import {BalancerSepoliaAddresses} from "../../test/balancer-adapter/BalancerSepoliaAddresses.sol";
import {ChainLinkFeedAddresses} from "../../test/balancer-adapter/ChainLinkFeedAddresses.sol";

contract EulSynths is BalancerSepoliaAddresses, ChainLinkFeedAddresses {
    ERC20Mintable public USDC;
    ERC20Mintable public eulUSD;
    ERC20Mintable public DAI;
    IBalancerPool public poolToken;

    BalancerAdapter public balancerAdapter;

    IEVC public evc;

    VaultCollateral public collateralVault;
    VaultMintable public mintableVault;

    mapping(address => address) internal assetToOracle;

    constructor() {
        // stablecoins creation, they already mint to the caller
        USDC = new ERC20Mintable("USDC", "USD Coin", 6);
        console.log("USDC", address(USDC));
        eulUSD = new ERC20Mintable("eulUSD", "Euler Vault Dollars", 18);
        console.log("eulUSD", address(eulUSD));
        DAI = new ERC20Mintable("DAI", "DAI Stablecoin", 18);
        console.log("DAI", address(DAI));

        eulUSD.mint(address(this), 1_000_000.0e18);
        USDC.mint(address(this), 2_000_000.0e6);
        DAI.mint(address(this), 2_000_000.0e18);

        // EVC
        evc = new EthereumVaultConnector();

        // balancer contracts
        balancerAdapter = new BalancerAdapter(
            CSP_FACTORY,
            BALANCER_VAULT,
            address(evc)
        );

        // add oracles
        assetToOracle[address(USDC)] = address(
            new WrappedRateProvider(USDC_FEED)
        );
        assetToOracle[address(DAI)] = address(
            new WrappedRateProvider(DAI_FEED)
        );

        create();
        init();
        joinPool();

        // vault contract
        IRMMock irm = new IRMMock();
        mintableVault = new VaultMintable(
            evc,
            address(eulUSD),
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
        eulUSD.transferOwnership(address(mintableVault));

        console.log("setCollateralFactor");
        mintableVault.setCollateralFactor(address(mintableVault), 0); // cf = 0, self-collateralization
        mintableVault.setCollateralFactor(address(collateralVault), 90); // cf = 0.9
    }

    function faucet(address asset) external {
        if (asset == address(USDC)) {
            USDC.mint(msg.sender, 10_000.0e6);
        } else if (asset == address(DAI)) {
            DAI.mint(msg.sender, 10_000.0e18);
        } else {
            revert("Invalid asset");
        }
    }

    function joinPool() internal {
        uint[] memory amounts = new uint256[](3);
        address adapter = address(balancerAdapter);

        (address[] memory assets, uint[] memory scales) = balancerAdapter
            .getDecimalScalesAndTokens();

        for (uint i = 0; i < assets.length; i++) {
            uint amountRaw = (1000.0 + i * 10);
            uint amount = amountRaw * scales[i];
            amounts[i] = amount;
            IERC20(assets[i]).transfer(adapter, amount);
        }
        // deposit balances to pool
        balancerAdapter.depositTo(amounts, address(this));
    }

    function init() private {
        uint[] memory amounts = new uint256[](4);

        address adapter = address(balancerAdapter);

        (address[] memory assets, uint[] memory scales) = balancerAdapter
            .getOriginalDecimalScalesAndTokens();
        address balancerPool = balancerAdapter.pool();
        for (uint i = 0; i < assets.length; i++) {
            address token = assets[i];
            if (token != balancerPool) {
                uint amountRaw = (10.0 + i * 10) * 1e18;
                uint amount = amountRaw / scales[i];
                amounts[i] = amount;
                IERC20(assets[i]).transfer(adapter, amount);
            }
        }

        address recipient = address(this);
        balancerAdapter.initializePool(amounts, recipient);

        poolToken = IBalancerPool(balancerAdapter.pool());
    }

    function create() private {
        address[] memory tokens = new address[](3);
        address[] memory ratePrivder = new address[](3);

        tokens[0] = address(eulUSD);
        tokens[1] = address(USDC);
        tokens[2] = address(DAI);

        // sort tokens
        tokens = bubbleSort(tokens);

        // align oracles
        ratePrivder[0] = assetToOracle[tokens[0]];
        ratePrivder[1] = assetToOracle[tokens[1]];
        ratePrivder[2] = assetToOracle[tokens[2]];

        balancerAdapter.createPool(tokens, ratePrivder);
    }

    function bubbleSort(
        address[] memory array
    ) private pure returns (address[] memory) {
        bool done = false;
        while (!done) {
            done = true;
            for (uint i = 1; i < array.length; i++) {
                if (array[i - 1] > array[i]) {
                    done = false;
                    address tmp = array[i - 1];
                    array[i - 1] = array[i];
                    array[i] = tmp;
                }
            }
        }
        return array;
    }
}
