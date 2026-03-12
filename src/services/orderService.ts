/**
 * orderService.ts — 订单服务
 *
 * 导入 calculator.ts 的 calculateTotal, calculateTotalWithTax
 * 导入 logger.ts 的 logInfo, logError, logWarn
 *
 * Case A: calculateTotal 引用目标
 * Case G: 多个 logger 函数引用目标（验证去重 + 多符号搜索）
 */
import { calculateTotal, calculateTotalWithTax } from '../utils/calculator'
import { logInfo, logError, logWarn } from '../utils/logger'
import type { CartItem } from '../utils/calculator'

export interface Order {
  id: string
  items: CartItem[]
  subtotal: number
  total: number
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered'
  createdAt: Date
}

/** 创建订单 */
export async function createOrder(items: CartItem[]): Promise<Order> {
  const subtotal = calculateTotal(items)
  const total = calculateTotalWithTax(items)

  logInfo('Creating order', `subtotal=${subtotal}, total=${total}`)

  if (items.length === 0) {
    logWarn('Attempted to create order with no items')
    throw new Error('购物车为空')
  }

  try {
    // 模拟 API 调用
    const order: Order = {
      id: `ORD-${Date.now()}`,
      items: [...items],
      subtotal,
      total,
      status: 'pending',
      createdAt: new Date(),
    }
    logInfo('Order created successfully', order.id)
    return order
  } catch (err) {
    logError('Failed to create order', String(err))
    throw err
  }
}

/** 取消订单 */
export async function cancelOrder(orderId: string): Promise<void> {
  logInfo('Cancelling order', orderId)
  // 模拟取消逻辑
  logWarn('Order cancelled', orderId)
}