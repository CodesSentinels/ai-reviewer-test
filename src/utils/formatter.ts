/**
 * formatter.ts — 格式化工具
 *
 * 测试 Case C: 修改内部函数 padZero（不导出）→ 不应触发跨文件分析
 */

/** 内部辅助函数（不导出） */
function padZero(num: number): string {
  return num < 10 ? `0${num}` : `${num}`
}

/** 格式化日期 */
export function formatDate(date: Date): string {
  const y = date.getFullYear()
  const m = padZero(date.getMonth() + 1)
  const d = padZero(date.getDate())
  return `${y}-${m}-${d}`
}

/** 格式化百分比 */
export function formatPercent(value: number): string {
  return `${(value * 100).toFixed(0)}%`
}

/** 截断文本 */
export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}