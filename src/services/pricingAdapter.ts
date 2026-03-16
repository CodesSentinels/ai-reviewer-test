/**
 * pricingAdapter.ts — 定价适配器
 *
 * 同时使用 **路径别名** (@/) 和 **符号别名** (as) 导入
 *
 * 测试 Case L: 路径别名 + 符号别名组合
 * import { calculateTotal as computeSubtotal } from '@/utils/calculator'
 * → 验证两种别名同时存在时，依赖分析能正确追踪
 */
import {
  calculateTotal as computeSubtotal,
  TAX_RATE as defaultTaxRate,
  formatPrice as fmtPrice,
} from '@/utils/calculator'
import { logInfo as info, logWarn as warn } from '@/utils/logger'
import type { CartItem } from '@/utils/calculator'

export type Currency = 'CNY' | 'USD' | 'EUR'

const EXCHANGE_RATES: Record<Currency, number> = {
  CNY: 1,
  USD: 0.14,
  EUR: 0.13,
}

/** 多币种定价 — 同时使用路径别名 + 符号别名 */
export function getPricing(
  items: CartItem[],
  currency: Currency = 'CNY',
): {
  subtotal: string
  tax: string
  total: string
  currency: Currency
} {
  const rate = EXCHANGE_RATES[currency]
  const subtotal = computeSubtotal(items) * rate
  const tax = subtotal * defaultTaxRate
  const total = subtotal + tax

  info('Pricing calculated', `currency=${currency}, total=${total}`)

  return {
    subtotal: fmtPrice(subtotal),
    tax: fmtPrice(tax),
    total: fmtPrice(total),
    currency,
  }
}

/** 批量定价比较 */
export function comparePricing(
  items: CartItem[],
  currencies: Currency[],
): Array<{ currency: Currency; total: string }> {
  if (items.length === 0) {
    warn('comparePricing called with empty items')
    return []
  }

  return currencies.map(currency => {
    const pricing = getPricing(items, currency)
    return { currency, total: pricing.total }
  })
}
