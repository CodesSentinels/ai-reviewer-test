/**
 * monitorService.ts — 监控服务
 *
 * 使用 namespace import 导入 calculator 模块
 *
 * 测试 Case I2: import * as calc from calculator → 验证 namespaceName.symbolName 模式搜索
 * 代码中使用 calc.calculateTotal()、calc.formatPrice() 等形式
 * → 修改 calculateTotal 时，应搜索 'calc.calculateTotal' 模式
 * → 修复前：只搜索 'calculateTotal' 或 'calc'，精度不够
 * → 修复后：step 6 构建 namespaceName.symbolName 加入搜索列表
 */
import * as calc from '../utils/calculator'
import * as logger from '../utils/logger'
import type { CartItem } from '../utils/calculator'

export interface MonitorMetrics {
  avgOrderValue: number
  totalRevenue: string
  orderCount: number
  alertLevel: 'normal' | 'warning' | 'critical'
}

/** 计算订单监控指标 — 通过 namespace 调用 calc.calculateTotal */
export function getOrderMetrics(orders: CartItem[][]): MonitorMetrics {
  let totalRevenue = 0

  for (const orderItems of orders) {
    const orderTotal = calc.calculateTotal(orderItems)
    totalRevenue += orderTotal
  }

  const avgOrderValue = orders.length > 0 ? totalRevenue / orders.length : 0
  const alertLevel = avgOrderValue < 100 ? 'warning' : 'normal'

  logger.logInfo('Order metrics calculated', `orders=${orders.length}, revenue=${totalRevenue}`)

  return {
    avgOrderValue,
    totalRevenue: calc.formatPrice(totalRevenue),
    orderCount: orders.length,
    alertLevel,
  }
}

/** 实时价格监控 — 多次通过 namespace 调用 */
export function monitorPriceChanges(
  before: CartItem[],
  after: CartItem[],
): { priceBefore: string; priceAfter: string; changed: boolean } {
  const totalBefore = calc.calculateTotal(before)
  const totalAfter = calc.calculateTotal(after)
  const changed = totalBefore !== totalAfter

  if (changed) {
    logger.logWarn(
      'Price change detected',
      `before=${calc.formatPrice(totalBefore)}, after=${calc.formatPrice(totalAfter)}`,
    )
  }

  return {
    priceBefore: calc.formatPrice(totalBefore),
    priceAfter: calc.formatPrice(totalAfter),
    changed,
  }
}
