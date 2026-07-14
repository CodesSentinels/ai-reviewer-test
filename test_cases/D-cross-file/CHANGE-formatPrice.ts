// 域 D：用此内容【替换基线的 utils/formatPrice.ts】，改签名 + 改默认值 + 新增参数。
// 预期 Bot 在审查评论/摘要中提及引用方：useCart.ts / ProductCard.vue /
// CartSummary.vue / server/api/products.ts。
export function formatPrice(
  amount: number,
  currency = 'USD', // 改默认值 CNY → USD（破坏性）
  locale = 'en-US' // 新增参数
): string {
  if (amount < 0) return 'N/A' // 新增负数处理
  return new Intl.NumberFormat(locale, {style: 'currency', currency}).format(
    amount
  )
}

export function parsePrice(text: string): number {
  const cleaned = text.replace(/[^0-9.]/g, '')
  const value = Number.parseFloat(cleaned)
  return Number.isFinite(value) ? value : 0
}
