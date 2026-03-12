/**
 * utils/index.ts — 工具模块统一导出
 *
 * 测试 Case H: re-export 链 → 验证 export { X } from './module' 被正确解析
 */

export { calculateTotal, calculateTotalWithTax, formatPrice, TAX_RATE } from './calculator'
export type { CartItem, Coupon } from './calculator'
export { formatDate, formatPercent, truncateText } from './formatter'
export { validateEmail, validatePhone, validatePassword } from './validator'
export { log, logInfo, logWarn, logError, logDebug, setLogLevel } from './logger'
export type { LogLevel } from './logger'