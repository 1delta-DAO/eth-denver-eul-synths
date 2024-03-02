import { multicall } from '@wagmi/core'
import { poolAssets } from '../src/constants'
import { useEffect, useState } from 'react'
import { useReadContract } from 'wagmi'
import { optimism } from 'viem/chains'
import { wagmiConfig } from '../_app'
import { parseBigInt } from '../src/formatters'

export const useFetchPrices = () => {

  const [prices, setPrices] = useState<Record<string, number> | null>(null)

  const poolAssetsWithPriceFeed = poolAssets.filter((asset) => asset.priceFeedAddress)

  const latestRoundDataAbi = [{
    type: 'function',
    name: 'latestRoundData',
    stateMutability: 'view',
    inputs: [],
    outputs: [
      { type: 'uint80', name: 'roundId' },
      { type: 'int256', name: 'answer' },
      { type: 'uint256', name: 'startedAt' },
      { type: 'uint256', name: 'updatedAt' },
      { type: 'uint80', name: 'answeredInRound' },
    ],
  }] as const

  const priceFeedContracts = poolAssetsWithPriceFeed.map((asset) => {
    return {
      address: asset.priceFeedAddress as `0x${string}`,
      abi: latestRoundDataAbi,
      functionName: 'latestRoundData',
    } as const
  })

  const wstETHRatioResult = useReadContract({
    abi: latestRoundDataAbi,
    address: '0x524299Ab0987a7c4B3c8022a35669DdcdC715a10',
    functionName: 'latestRoundData',
    chainId: optimism.id
  })

  const wstETHRatioBigInt = wstETHRatioResult.data?.[1]
  const wstETHRatio = parseBigInt(wstETHRatioBigInt, 18)

  useEffect(() => {
    const fetchAndSetPrices = async () => {
      if (!priceFeedContracts.length) return
      if (!wstETHRatio) return
      const results = await multicall(wagmiConfig, {
        contracts: priceFeedContracts,
        chainId: 1,
      })
      const pricesBigInt = results.map((price) => price.result?.[1])
      const prices = pricesBigInt.map((price) => parseBigInt(price, 8))
      const pricesObject = [
        poolAssetsWithPriceFeed.reduce((acc, asset, index) => {
          acc[asset.symbol] = prices[index]
          return acc
        }, {} as Record<string, number>),
        poolAssetsWithPriceFeed.filter((asset) => !asset.priceFeedAddress).reduce((acc, asset) => {
          acc[asset.symbol] = asset.defaultPrice || 0
          return acc
        }, {} as Record<string, number>)
      ].reduce((acc, obj) => ({ ...acc, ...obj }), {})
      const wstETHPrice = pricesObject['wstETH']
      pricesObject['wstETH'] = wstETHPrice * wstETHRatio
      setPrices(pricesObject)
    }
    const interval = setInterval(fetchAndSetPrices, 10000)
    return () => clearInterval(interval)
  }, [
    priceFeedContracts,
    wstETHRatio,
    poolAssetsWithPriceFeed
  ])

  return prices
}