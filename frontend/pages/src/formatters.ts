export const formatNumber = (value: number) => {
  return value.toLocaleString(undefined, {
    maximumFractionDigits: 2,
  })
}

export const formatRatioToPercent = (value: number) => {
  return `${(value * 100).toFixed(2)}%`
}