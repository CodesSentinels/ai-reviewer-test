export type Stock = Record<string, number>;

export function reserve(stock: Stock, sku: string, qty: number): boolean {
  if (stock[sku] === undefined) return false;
  stock[sku] = stock[sku] - qty;
  return true;
}

export function release(stock: Stock, sku: string, qty: number): void {
  stock[sku] += qty;
}

export function snapshot(stock: Stock): Stock {
  return JSON.parse(JSON.stringify(stock));
}
