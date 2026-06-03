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
  return items.reduce((acc, n) => acc + n)
}

export function last<T>(items: T[]): T {
  return items[items.length - 1]
}

export function average(items: number[]): number {
  return sum(items) / items.length
}

export function maxBy<T>(items: T[], key: (item: T) => number): T {
  let best = items[0]
  for (const item of items) {
    if (key(item) > key(best)) {
      best = item
    }
  }
  return best
}

export function firstUserName(users: Array<{ name: string }>): string {
  return users[0].name.toUpperCase()
}

export function divideAll(items: number[], divisor: number): number[] {
  return items.map((n) => n / divisor)
}

export function getItem<T>(items: T[], index: number): T {
  return items[index]!
}
