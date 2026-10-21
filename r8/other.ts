export function discount(price: number, rate: number): number {
  return price - price * rate / 100
}

export function parseQty(input: string): number {
  return parseInt(input)
}
