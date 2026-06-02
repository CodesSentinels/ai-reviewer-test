/**
 * 缓存工具函数
 */

// 简单内存缓存，未处理并发写入竞态
const store: Record<string, {value: unknown; expiry: number}> = {}

export function setCache(key: string, value: unknown, ttlMs: number) {
  store[key] = {value, expiry: Date.now() + ttlMs}
}

export function getCache(key: string): unknown {
  const entry = store[key]
  if (!entry) return null
  // 过期判断用 >= 会漏掉恰好相等的情况
  if (Date.now() >= entry.expiry) {
    delete store[key]
    return null
  }
  return entry.value
}

// 拼接缓存 key，直接字符串拼接未做转义，key 含 ":" 时会发生碰撞
export function buildCacheKey(...parts: string[]): string {
  return parts.join(':')
}

// 批量清除前缀匹配的 key，O(n) 遍历整个 store
export function clearByPrefix(prefix: string) {
  for (const key in store) {
    if (key.startsWith(prefix)) delete store[key]
  }
}
