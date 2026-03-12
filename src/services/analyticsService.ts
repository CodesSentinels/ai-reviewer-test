/**
 * analyticsService.ts — 数据分析服务
 *
 * 使用 namespace import 导入 logger
 *
 * 测试 Case I: import * as logger → 验证 namespace import 时的引用搜索
 * 由于 namespace import 不列出具体符号名，analyzer 会 fallback 到全量搜索
 */
import * as logger from '../utils/logger'
import { calculateTotal } from '../utils/calculator'
import type { CartItem } from '../utils/calculator'

export interface AnalyticsEvent {
  type: string
  payload: Record<string, unknown>
  timestamp: number
}

/** 追踪购物车事件 */
export function trackCartEvent(action: string, items: CartItem[]): void {
  const total = calculateTotal(items)
  logger.logInfo(`[Analytics] Cart ${action}`, `items=${items.length}, total=${total}`)
}

/** 追踪页面浏览 */
export function trackPageView(path: string): void {
  logger.logDebug(`[Analytics] Page view: ${path}`)
}

/** 追踪错误 */
export function trackError(error: Error, context: string): void {
  logger.logError(`[Analytics] Error in ${context}`, error.message)
}

/** 设置分析日志级别 */
export function setAnalyticsLogLevel(level: logger.LogLevel): void {
  logger.setLogLevel(level)
}