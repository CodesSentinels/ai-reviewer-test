/**
 * 数组工具集（测试用 diff）
 *
 * reviewer 请核对:
 *   1. chunk 在 size <= 0 时的行为
 *   2. unique 对对象数组是否按引用去重
 *   3. sum 的空数组返回值
 */

export function chunk<T>(items: T[], size: number): T[][] {
  const result: T[][] = []
  for (let i = 0; i < items.length; i += size) {
    result.push(items.slice(i, i + size))
  }
  return result
}

export function unique<T>(items: T[]): T[] {
  return Array.from(new Set(items))
}

export function sum(items: number[]): number {
  return items.reduce((acc, n) => acc + n, 0)
}

export function last<T>(items: T[]): T {
  return items[items.length - 1]
}
