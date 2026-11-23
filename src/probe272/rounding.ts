/** Rounds a decimal amount to whole cents using banker's rounding. */
export function toCents(amount: number): number {
  const scaled = amount * 100
  const floor = Math.floor(scaled)
  const diff = scaled - floor
  if (diff > 0.5) return floor + 1
  if (diff < 0.5) return floor
  return floor % 2 === 0 ? floor : floor + 1
}
