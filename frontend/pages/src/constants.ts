
export interface PoolAsset {
  symbol: string
  name: string
  icon: string
  decimals: number
  priceFeedAddress?: string
  defaultPrice?: number
  address?: string
}

export const payAssets: PoolAsset[] = [
  {
    symbol: "wstETH",
    name: "Wrapped stETH",
    icon: "https://assets.coingecko.com/coins/images/18834/standard/wstETH.png",
    decimals: 18,
    priceFeedAddress: "0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8"
  },
  {
    symbol: "ETH",
    name: "Ethereum",
    icon: "https://static-00.iconduck.com/assets.00/ethereum-cryptocurrency-icon-512x512-u1g6py59.png",
    decimals: 18,
    priceFeedAddress: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
  },
  {
    symbol: "DAI",
    name: "Dai",
    icon: "https://assets.coingecko.com/coins/images/9956/standard/Badge_Dai.png?1696509996",
    decimals: 18,
    priceFeedAddress: "0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9",
    address: "0xbBF92F1A64Ad4f0292e05fd8E690fA8B872f835b"
  },
  {
    symbol: "USDC",
    name: "USD Coin",
    icon: "https://assets.coingecko.com/coins/images/6319/large/USD_Coin_icon.png",
    decimals: 6,
    priceFeedAddress: "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6",
    address: "0xB67881Af90F005BE8c7553793F89BDbb3FD7448f"
  },
  {
    symbol: "USDT",
    name: "Tether",
    icon: "https://static-00.iconduck.com/assets.00/tether-cryptocurrency-icon-2048x2048-dp13oydi.png",
    decimals: 6,
    priceFeedAddress: "0x3E7d1eAB13ad0104d2750B8863b489D65364e32D",
    address: "0xaa8e23fb1079ea71e0a56f48a2aa51851d8433d0"
  },
  {
    symbol: "WBTC",
    name: "Wrapped Bitcoin",
    icon: "https://assets.coingecko.com/coins/images/7598/large/wrapped_bitcoin_wbtc.png",
    decimals: 8,
    priceFeedAddress: "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c"
  },
]

export const synthAssets: PoolAsset[] = [
  {
    symbol: "eulUSD",
    name: "Euler Dollar",
    icon: "https://assets.coingecko.com/coins/images/28445/standard/0xa0d69e286b938e21cbf7e51d71f6a4c8918f482f.png",
    decimals: 18,
    defaultPrice: 1.01,
    address: "0x9f5e877f7a03f50c0319a6e15289283d6a8ac2e3"
  },
  {
    symbol: 'eulLTC',
    name: 'Euler Litecoin',
    icon: 'https://assets.coingecko.com/coins/images/2/standard/litecoin.png',
    decimals: 18,
    priceFeedAddress: "0x6AF09DF7563C363B5763b9102712EbeD3b9e859B"
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
    apr: 0.13451,
    stakingApr: 0.2412,
    tvl: 1000000,
  },
  {
    assets: [
      symbolToAsset("USDC")!,
      symbolToAsset("DAI")!,
      symbolToAsset("eulUSD")!,
    ],
    apr: 0.1789,
    tvl: 2000000,
    totalSupply: 100000,
  },
  {
    assets: [
      symbolToAsset("WBTC")!,
      symbolToAsset("eulLTC")!,
    ],
    apr: 0.323,
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

export const approveAndAllowanceAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "spender",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "approve",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "spender",
        "type": "address"
      }
    ],
    "name": "allowance",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]