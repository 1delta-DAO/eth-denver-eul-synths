# eulSynth

## Tagline

eulSynths is a universal DeFi yield product platform built on Euler and Balancer.

The protocol allows users to leverage DEX liquidity from protocols like Balancer to multiply their intrinsic yield. This has applications across multiple domains:

- On top of LSD yields, they can also leverage their DEX yield exposure
- The architecture allows for native miniting of synthetic assets together with direct liquidity bootstrapping via Balacner Composed Stable Pools


## What problems do we solve

Getting optimal yield has been very duifficult in the past. A multitude of synthetic assets and derivatives (especially LSDs) allow for multiple variations of generating income.

One could either add it to DEX pools to earn fees on the high volumes or just leverage them up on lending protocol.
eulSynth is the first protocol that allows for flexible and dynamic onboarding of DEX liquidity.

## Challenges

Balancer and Euler are both highly composable protocols, however, their composability comes with a high degree of complexity.

Balancer for instance allowed us to select from a multitude of Stable Pools, each of which have highly specific parametrizations. On top of that, Euler's implementation of the Vault Connector is ebntirely new, as such, we had to take a long time to even just understand how we could make them work together.

## Technologies 

- Synthetic assets enabled by ChainLink's price feeds
- Balancer's Composable Stable Pools (which are also oracle-based)
- Euler's Ethereum Vault Connector that allows for flexible batching and single-click leveraged Balancer DEX liquidity provision