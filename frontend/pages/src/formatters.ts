

const roundFloat = (value: number, precision: number = 2) => {
  const multiplier = Math.pow(10, precision || 0);
  return Math.round(value * multiplier) / multiplier;
}