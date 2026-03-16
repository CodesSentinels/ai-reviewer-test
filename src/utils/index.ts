/**
 * utils/index.ts — 工具模块统一导出
 *
 * 测试 Case H: re-export 链 → 验证 export { X } from './module' 被正确解析
 * 测试 Case H2: barrel file 间接引用 → 步骤 5.5 追踪通过 barrel 的间接消费者
 * 测试 Case H3: export * from → 通配符 re-export 被正确解析
 */

export { calculateTotal, calculateTotalWithTax, formatPrice, TAX_RATE } from './calculator'
export type { CartItem, Coupon } from './calculator'
export { formatDate, formatPercent, truncateText } from './formatter'
export { validateEmail, validatePhone, validatePassword } from './validator'
export { log, logInfo, logWarn, logError, logDebug, setLogLevel } from './logger'
export type { LogLevel } from './logger'

// Case H3: export * from — 通配符 re-export
// mathHelpers 的所有导出（包括 default export roundPrice）通过 * 重新导出
export * from './mathHelpers'