// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import "../interfaces/IPriceOracle.sol";
import "../balancer-adapter/interfaces/IVault.sol";
import {AggregatorV3Interface} from "../interfaces/chainlink/AggregatorV3Interface.sol";
import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

contract BalancerPoolPriceContract is IPriceOracle {
    uint256 internal constant USD_SCALE = 100_000_000;
    IBalancerVault internal balancer;
    bytes32 internal poolId;
    IERC20 internal pool;
    AggregatorV3Interface[] internal priceFeed;
    uint256[] internal decimalMultipliers;

    constructor(
        IBalancerVault _balancer,
        bytes32 _poolId,
        IERC20 _pool,
        AggregatorV3Interface[] memory _priceFeed
    ) {
        //priceFeed[usdc] = AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E); // USDC/USD
        //priceFeed[dai] = AggregatorV3Interface(0x14866185B1962B63C3Ea9E03Bc1da838bab34C19); // DAI/USD
        balancer = _balancer;
        poolId = _poolId;
        pool = _pool;
        priceFeed = _priceFeed;
        (IERC20[] memory tokens, , ) = balancer.getPoolTokens(poolId);
        uint8 targetDecimals = IERC20Metadata(address(_pool)).decimals();
        for (uint8 i = 0; i < tokens.length; i++) {
            decimalMultipliers[i] = 10 ** (targetDecimals - IERC20Metadata(address(tokens[i])).decimals());
        }
    }

    /// @notice Returns the name of the price oracle.
    function name() external view returns (string memory) {
        return "chainlink";
    }

    /// @notice Returns the quote for a given amount of base asset in quote asset.
    /// @param amount The amount of base asset.
    /// @param base The address of the base asset.
    /// @param quote The address of the quote asset.
    /// @return out The quote amount in quote asset.
    function getQuote(
        uint256 amount,
        address base,
        address quote
    ) external view returns (uint256 out) {
        uint256 poolTokenPrice = getPrice(); // target / pool decimals
        out = poolTokenPrice * amount / decimalMultipliers[0]; // decimalMultipliers[0] should always match quote asset to simplify logic        
    }

    /// @notice Returns the bid and ask quotes for a given amount of base asset in quote asset.
    /// @param amount The amount of base asset.
    /// @param base The address of the base asset.
    /// @param quote The address of the quote asset.
    /// @return bidOut The bid quote amount in quote asset.
    /// @return askOut The ask quote amount in quote asset.
    function getQuotes(
        uint256 amount,
        address base,
        address quote
    ) external view returns (uint256 bidOut, uint256 askOut) {
        uint256 poolTokenPrice = getPrice(); // target / pool decimals
        bidOut = poolTokenPrice * amount / decimalMultipliers[0]; // decimalMultipliers[0] should always match quote asset to simplify logic
        askOut = bidOut;
    }

    function getPrice() internal view returns (uint256) {
        (IERC20[] memory tokens, uint256[] memory balances, ) = balancer.getPoolTokens(poolId);

        assert(tokens.length == priceFeed.length);

        uint256 poolPrice = 0;
        for (uint8 i = 0; i < tokens.length; i++) {
            (, int256 price, , , ) = priceFeed[i].latestRoundData();
            assert(price >= 0);
            poolPrice += balances[i] * uint256(price) * decimalMultipliers[i] / USD_SCALE;
        }

        uint256 totalSupply = pool.totalSupply();
        
        return totalSupply > 0 ? poolPrice / totalSupply : 0;
    }
}