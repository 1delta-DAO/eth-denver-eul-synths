
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
    icon: "https://assets.coingecko.com/coins/images/279/large/ethereum.png",
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

export const synthAssets: PoolAsset[] = []

export const poolAssets = [...payAssets, ...synthAssets]