import {formatCents} from './money'

export interface LineItem {
  name: string
  price: number // decimal amount, e.g. 19.99
  qty: number
}

export function invoiceTotalLabel(items: LineItem[]): string {
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0)
  return formatCents(total, 'USD')
}
