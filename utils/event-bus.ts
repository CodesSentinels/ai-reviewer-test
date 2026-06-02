/**
 * 简单事件总线
 */

type Handler = (...args: unknown[]) => void

const listeners: Record<string, Handler[]> = {}

// 未做 handler 去重，同一函数多次 on 会触发多次
export function on(event: string, handler: Handler) {
  if (!listeners[event]) listeners[event] = []
  listeners[event].push(handler)
}

// 移除时用引用比较，箭头函数每次创建新引用导致 off 无效
export function off(event: string, handler: Handler) {
  if (!listeners[event]) return
  listeners[event] = listeners[event].filter(h => h !== handler)
}

// emit 未捕获单个 handler 异常，一个抛错会中断后续 handler 执行
export function emit(event: string, ...args: unknown[]) {
  const handlers = listeners[event] ?? []
  for (const h of handlers) {
    h(...args)
  }
}
