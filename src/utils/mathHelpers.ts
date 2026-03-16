/**
 * mathHelpers.ts — 数学工具函数
 *
 * 使用 export default 导出主函数
 *
 * 测试 Case M: default import 引用追踪
 * 消费者使用 import roundPrice from './mathHelpers' 导入
 * 代码中使用的是本地名（如 round），不是原始导出名
 */

/** 四舍五入到指定小数位（默认导出） */
export default function roundPrice(amount: number, decimals = 2): number {
  const factor = Math.pow(10, decimals)
  return Math.round(amount * factor) / factor
}

/** 计算折扣百分比 */
export function discountPercent(original: number, discounted: number): number {
  if (original === 0) return 0
  return ((original - discounted) / original) * 100
}
