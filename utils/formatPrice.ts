/**
 * 价格格式化工具。被 composables/useCart、components/ProductCard、
 * components/CartSummary 多处引用——是跨文件依赖分析的核心上游符号。
 */
export function formatPrice(amount: number, currency = 'CNY'): string {
  if (!Number.isFinite(amount)) {
    return '—'
  }
  return new Intl.NumberFormat('zh-CN', {style: 'currency', currency}).format(
    amount
  )
}

export function parsePrice(text: string): number {
  const cleaned = text.replace(/[^0-9.]/g, '')
  const value = Number.parseFloat(cleaned)
  return Number.isFinite(value) ? value : 0
}
