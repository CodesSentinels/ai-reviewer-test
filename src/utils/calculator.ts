/**
 * calculator.ts — 价格计算工具
 *
 * 测试 Case A: 修改 calculateTotal 签名
 * 测试 Case B: 修改 TAX_RATE 值
 */

export interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

export interface Coupon {
  code: string;
  discount: number;
}

/** 计算购物车总价 */
// export function calculateTotal(items: CartItem[]): number {
//   return items.reduce((sum, item) => sum + item.price * item.quantity, 0)
// }

export function calculateTotal(items: CartItem[], coupon?: Coupon): number {
  const subtotal = items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0,
  );
  if (coupon) {
    return subtotal * (1 - coupon.discount);
  }
  return subtotal;
}

/** 税率 */
export const TAX_RATE = 0.08;

/** 计算含税总价 */
export function calculateTotalWithTax(items: CartItem[]): number {
  const total = calculateTotal(items);
  return total * (1 + TAX_RATE);
}

/** 格式化价格 */
export function formatPrice(amount: number): string {
  return `¥${amount.toFixed(2)}`;
}
