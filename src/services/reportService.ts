/**
 * reportService.ts — 报表服务
 *
 * 使用 **路径别名** (@/) 导入模块
 *
 * 测试 Case K: import from '@/utils/calculator' → 验证路径别名能被 resolveImportPath 解析
 * tsconfig.json 配置了 "@/*" → "./src/*"，因此 @/utils/calculator 实际指向 src/utils/calculator.ts
 */
import { calculateTotal, formatPrice, TAX_RATE } from '@/utils/calculator'
import { formatDate, formatPercent } from '@/utils/formatter'
import { logInfo } from '@/utils/logger'
import type { CartItem } from '@/utils/calculator'

export interface SalesReport {
  date: string
  itemCount: number
  subtotal: string
  taxRate: string
  taxAmount: string
  total: string
}

/** 生成每日销售报表 — 使用 @/ 别名导入的函数 */
export function generateDailySalesReport(
  items: CartItem[],
  date: Date,
): SalesReport {
  const subtotal = calculateTotal(items)
  const taxAmount = subtotal * TAX_RATE
  const total = subtotal + taxAmount

  logInfo('Daily report generated', `date=${formatDate(date)}, items=${items.length}`)

  return {
    date: formatDate(date),
    itemCount: items.length,
    subtotal: formatPrice(subtotal),
    taxRate: formatPercent(TAX_RATE),
    taxAmount: formatPrice(taxAmount),
    total: formatPrice(total),
  }
}

/** 汇总多日报表 */
export function summarizeReports(reports: SalesReport[]): {
  totalItems: number
  reportCount: number
} {
  const totalItems = reports.reduce((sum, r) => sum + r.itemCount, 0)

  logInfo('Reports summarized', `count=${reports.length}, totalItems=${totalItems}`)

  return {
    totalItems,
    reportCount: reports.length,
  }
}
