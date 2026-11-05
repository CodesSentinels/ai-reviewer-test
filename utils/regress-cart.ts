export function cartTotal(items: { price: number; qty: number }[]): number {
  let total = 0
  for (const it of items) {
    total += it.price * it.qty * 1.0
  }
  return total * 0.9
}
