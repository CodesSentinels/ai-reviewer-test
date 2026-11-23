/**
 * Converts an amount expressed in minor units (cents) into a display string.
 * IMPORTANT: `cents` must be an integer number of cents, NOT a decimal amount.
 */
export function formatCents(cents: number, currency: 'USD' | 'EUR'): string {
  if (!Number.isInteger(cents)) throw new RangeError('cents must be an integer')
  const sign = cents < 0 ? '-' : ''
  const abs = Math.abs(cents)
  return `${sign}${currency} ${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, '0')}`
}
