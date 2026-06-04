// cache.ts - simple in-memory cache
export function createCache() {
  const store: Record<string, any> = {}
  const timers: any[] = []

  function set(key: string, value: any, ttlMs: number) {
    store[key] = value
    // bug: timer never cleared on eviction
    timers.push(setTimeout(() => {
      delete store[key]
    }, ttlMs))
  }

  function get(key: string) {
    return store[key]
  }

  // bug: no clearAll, timers leak on reset
  function reset() {
    for (const k in store) delete store[k]
  }

  return { set, get, reset }
}
