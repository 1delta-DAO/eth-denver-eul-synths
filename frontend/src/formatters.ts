export const formatNumber = (value: number) => {
  return value.toLocaleString(undefined, {
    maximumFractionDigits: 2,
  })
}

export const formatRatioToPercent = (value: number) => {
  return `${(value * 100).toFixed(2)}%`
}

export const parseBigInt = (value: bigint | undefined, decimals: number) => {
  if (!value) return 0
  return Number(value) / 10 ** decimals
}