/**
 * 价格格式化工具
 *
 * 测试场景 3: 被 components/ProductCard.vue 和 pages/products/[id].vue 引用
 */
export function formatPrice(
  amount: number,
  currency: string = "CNY",
  // 场景 3: 工具函数引用
  // currency: string = "USD",
  locale: string = "zh-CN"
): string {
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency
  }).format(amount)
}
