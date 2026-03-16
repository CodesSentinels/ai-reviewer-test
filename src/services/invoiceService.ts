/**
 * invoiceService.ts — 发票服务
 *
 * 使用 **default import** 导入 mathHelpers 的默认导出
 *
 * 测试 Case M: import round from '../utils/mathHelpers'
 * → 消费者使用本地名 `round` 而非原始导出名 `roundPrice`
 * → 修改 roundPrice 时，搜索 'roundPrice' 找不到 'round'
 * → 修复后：dep entry 记录 defaultImportName='round'，step 6 自动搜索本地名
 */
import round from '../utils/mathHelpers'
import { calculateTotal, TAX_RATE, formatPrice } from '../utils/calculator'
import { logInfo } from '../utils/logger'
import type { CartItem } from '../utils/calculator'

export interface Invoice {
  invoiceNo: string
  items: CartItem[]
  subtotal: string
  tax: string
  total: string
  issuedAt: string
}

/** 生成发票 — 使用 default import 的本地名 round */
export function generateInvoice(items: CartItem[]): Invoice {
  const subtotal = calculateTotal(items)
  const tax = round(subtotal * TAX_RATE)
  const total = round(subtotal + tax)

  logInfo('Invoice generated', `items=${items.length}, total=${total}`)

  return {
    invoiceNo: `INV-${Date.now()}`,
    items: [...items],
    subtotal: formatPrice(round(subtotal)),
    tax: formatPrice(tax),
    total: formatPrice(total),
    issuedAt: new Date().toISOString(),
  }
}

/** 计算发票合计（带精度控制）— 多次使用 round */
export function calculateInvoiceTotals(
  subtotal: number,
  taxRate: number,
  discount = 0,
): { tax: number; discount: number; total: number } {
  const discountAmount = round(subtotal * discount)
  const afterDiscount = round(subtotal - discountAmount)
  const tax = round(afterDiscount * taxRate)
  const total = round(afterDiscount + tax)

  return { tax, discount: discountAmount, total }
}
