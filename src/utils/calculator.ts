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

/** 原代码 计算购物车总价 */
export function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Case A：修改导出函数签名 → 检测到多个调用方
// export function calculateTotal(items: CartItem[], coupon?: Coupon): number {
//   const subtotal = items.reduce(
//     (sum, item) => sum + item.price * item.quantity,
//     0,
//   );
//   if (coupon) {
//     return subtotal * (1 - coupon.discount);
//   }
//   return subtotal;
// }

// Case A2：修改导出函数签名（破坏性变更）→ 检测到调用方报错
// export function calculateTotal(items: CartItem[], currency: Currency): Money {
//   const subtotal = items.reduce(
//     (sum, item) => sum + item.price * item.quantity,
//     0,
//   );
//   return {
//     amount: subtotal,
//     currency: currency.code,
//     formatted: `${currency.symbol}${subtotal.toFixed(2)}`,
//   };
// }

/** 税率 */
export const TAX_RATE = 0.1;

/** 计算含税总价 */
export function calculateTotalWithTax(items: CartItem[]): number {
  const total = calculateTotal(items);
  return total * (1 + TAX_RATE);
}

/** 格式化价格 */
export function formatPrice(amount: number): string {
  return `¥${amount.toFixed(2)}`;
}
