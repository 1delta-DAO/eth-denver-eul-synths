// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {ICSPFactory, IRateProvider} from "./interfaces/ICSPFactory.sol";
import {AggregatorV3Interface} from "./interfaces/IAggregator.sol";

contract WrappedRateProvider is IRateProvider {
    address private immutable CHAIN_LINK_AGGREGATOR;

    // multiplying a ChainLink pice with this makes it 18 decimals
    uint256 PRICE_SCALE = 10 ** (18 - 8);

    constructor(address chainLinkAggregator) {
        CHAIN_LINK_AGGREGATOR = chainLinkAggregator;
    }

    function getRate() external view override returns (uint256 rate) {
        (
            ,
            // uint80 roundId,
            int256 answer, // uint256 startedAt, // uint256 updatedAt, // uint80 answeredInRound
            ,
            ,

        ) = AggregatorV3Interface(CHAIN_LINK_AGGREGATOR).latestRoundData();
        return uint256(answer) * PRICE_SCALE;
    }
}
