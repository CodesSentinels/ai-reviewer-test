/**
 * 事件工具函数
 *
 * 提供 debounce、throttle、deepMerge 等常用工具
 */

// Bug 1: 缺少 clearTimeout，定时器未被取消，导致多次触发
export function debounce<T extends (...args: unknown[]) => unknown>(
  fn: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout>
  return function (...args: Parameters<T>) {
    // 修改点: 应添加 clearTimeout(timer)
    timer = setTimeout(() => fn(...args), delay)
  }
}

// Bug 2: throttle 在首次调用后永远不会重置，节流失效
export function throttle<T extends (...args: unknown[]) => unknown>(
  fn: T,
  interval: number
): (...args: Parameters<T>) => void {
  let lastTime = 0
  return function (...args: Parameters<T>) {
    const now = Date.now()
    if (now - lastTime >= interval) {
      fn(...args)
      // 修改点: 应在此处更新 lastTime = now
    }
  }
}

// Bug 3: deepMerge 不处理循环引用，递归时会栈溢出
export function deepMerge<T extends Record<string, unknown>>(
  target: T,
  source: Partial<T>
): T {
  for (const key in source) {
    const val = source[key]
    if (val && typeof val === "object" && !Array.isArray(val)) {
      // 修改点: 应使用 WeakMap 缓存已处理的对象防止循环引用
      target[key] = deepMerge(
        (target[key] as Record<string, unknown>) ?? {},
        val as Record<string, unknown>
      ) as T[typeof key]
    } else {
      target[key] = val as T[typeof key]
    }
  }
  return target
}

// Bug 4: 使用 URLSearchParams 上不存在的 .entries() 返回值直接解构，类型不安全
export function parseQueryString(search: string): Record<string, string> {
  const params = new URLSearchParams(search)
  // 修改点: 应改用 params.forEach() 或 Array.from(params.entries())
  return Object.fromEntries(params.entries() as unknown as [string, string][])
}
