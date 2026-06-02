/**
 * 重试工具函数
 */

// 固定间隔重试，未做指数退避，高频失败场景会打满下游
export async function retry<T>(
  fn: () => Promise<T>,
  times: number,
  interval: number
): Promise<T> {
  for (let i = 0; i < times; i++) {
    try {
      return await fn()
    } catch (e) {
      if (i === times - 1) throw e
      await new Promise(r => setTimeout(r, interval))
    }
  }
  throw new Error('unreachable')
}

// 超时包装，未清理内部 timer 导致 Node.js 进程无法退出
export function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    setTimeout(() => reject(new Error(`Timeout after ${ms}ms`)), ms)
    promise.then(resolve, reject)
  })
}
