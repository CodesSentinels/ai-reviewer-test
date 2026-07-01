// generated: 2026-07-01 11:40:06
/**
 * 价格格式化工具
 *
 * Breaking change:
 *   - currency 变为必需参数（移除默认值）
 *   - 参数顺序改为 (amount, locale, currency)
 *   - 新增负数保护
 *
 * 受影响引用方:
 *   - components/ProductCard.vue: formatPrice(props.price) 调用缺少新必需参数
 *   - 其他调用 formatPrice 且未传 locale/currency 的地方
 */
export function formatPrice(
  amount: number,
  locale: string,       // 新增: 展示区域（原无此参数）
  currency: string      // 改动: 移除默认值 "USD"，变为必需参数
): string {
  if (amount < 0) return 'N/A'
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency
  }).format(amount)
}
