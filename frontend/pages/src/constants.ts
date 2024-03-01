
export interface PoolAsset {
  symbol: string
  name: string
  icon: string
  decimals: number
}

export const payAssets: PoolAsset[] = [
  {
    symbol: "wstETH",
    name: "Wrapped stETH",
    icon: "https://assets.coingecko.com/coins/images/18834/standard/wstETH.png",
    decimals: 18
  },
  {
    symbol: "ETH",
    name: "Ethereum",
    icon: "https://static-00.iconduck.com/assets.00/ethereum-cryptocurrency-icon-512x512-u1g6py59.png",
    decimals: 18
  },
  {
    symbol: "DAI",
    name: "Dai",
    icon: "https://assets.coingecko.com/coins/images/9956/standard/Badge_Dai.png?1696509996",
    decimals: 18
  },
  {
    symbol: "USDC",
    name: "USD Coin",
    icon: "https://assets.coingecko.com/coins/images/6319/large/USD_Coin_icon.png",
    decimals: 6
  },
  {
    symbol: "USDT",
    name: "Tether",
    icon: "https://static-00.iconduck.com/assets.00/tether-cryptocurrency-icon-2048x2048-dp13oydi.png",
    decimals: 6
  },
  {
    symbol: "WBTC",
    name: "Wrapped Bitcoin",
    icon: "https://assets.coingecko.com/coins/images/7598/large/wrapped_bitcoin_wbtc.png",
    decimals: 8
  },
]

export const synthAssets: PoolAsset[] = [
  {
    symbol: "eUSD",
    name: "Euler Dollar",
    icon: "https://assets.coingecko.com/coins/images/28445/standard/0xa0d69e286b938e21cbf7e51d71f6a4c8918f482f.png",
    decimals: 18
  },
  {
    symbol: 'eLTC',
    name: 'Euler Litecoin',
    icon: 'https://assets.coingecko.com/coins/images/2/standard/litecoin.png',
    decimals: 18
  }
]

export const poolAssets = [...payAssets, ...synthAssets]

export const symbolToAsset = (symbol: string): PoolAsset | undefined => {
  return poolAssets.find((asset) => asset.symbol === symbol)
}

export interface Pool {
  assets: PoolAsset[]
  apr: number
  stakingApr?: number // if staking is available
  tvl: number
  totalSupply?: number // for e-assets
}

export const pools: Pool[] = [
  {
    assets: [
      symbolToAsset("wstETH")!,
      symbolToAsset("ETH")!,
    ],
    apr: 0.1,
    stakingApr: 0.2,
    tvl: 1000000,
  },
  {
    assets: [
      symbolToAsset("USDC")!,
      symbolToAsset("DAI")!,
      symbolToAsset("eUSD")!,
    ],
    apr: 0.2,
    tvl: 2000000,
    totalSupply: 100000,
  },
  {
    assets: [
      symbolToAsset("WBTC")!,
      symbolToAsset("eLTC")!,
    ],
    apr: 0.3,
    tvl: 3000000,
    totalSupply: 2000,
  },
  {
    assets: [
      symbolToAsset("USDC")!,
      symbolToAsset("USDT")!,
      symbolToAsset("DAI")!,
    ],
    apr: 0.4,
    tvl: 4000000,
  }
]