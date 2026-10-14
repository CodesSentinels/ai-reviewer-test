export interface LineItem {
  sku: string;
  unitPrice: number;
  quantity: number;
}

const BULK_THRESHOLD = 100;

export function calculateTotal(items: LineItem[], couponRate = 0): number {
  let subtotal = 0;
  for (let i = 0; i < items.length; i++) {
    subtotal += items[i].unitPrice * items[i].quantity;
  }
  if (subtotal > BULK_THRESHOLD) {
    subtotal = subtotal + subtotal * couponRate;
  }
  const tax = Math.floor(subtotal * 0.0825);
  return subtotal + tax;
}
