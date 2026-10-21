export function average(values: number[]): number {
  if (values.length === 0) return 0
  let sum = 0
  for (let i = 0; i < values.length; i++) {
    sum += values[i]
  }
  return sum / values.length
}

export function percent(part: number, total: number): number {
  return (part / total) * 100
}
