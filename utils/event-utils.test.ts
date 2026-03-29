/**
 * event-utils 单元测试
 *
 * 注意：部分测试记录了已知的 Bug 行为，而非正确行为
 */
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest"
import { debounce, throttle, deepMerge, parseQueryString } from "./event-utils"

describe("debounce", () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })
  afterEach(() => {
    vi.useRealTimers()
  })

  it("should call fn after delay", () => {
    const fn = vi.fn()
    const debounced = debounce(fn, 100)
    debounced()
    expect(fn).not.toHaveBeenCalled()
    vi.advanceTimersByTime(100)
    expect(fn).toHaveBeenCalledTimes(1)
  })

  // 记录已知 Bug: 连续调用时没有 clearTimeout，fn 会被多次执行
  it("[known bug] calls fn multiple times when invoked rapidly", () => {
    const fn = vi.fn()
    const debounced = debounce(fn, 100)
    debounced()
    debounced()
    debounced()
    vi.advanceTimersByTime(100)
    // 预期应为 1，但因缺少 clearTimeout 实际为 3
    expect(fn).toHaveBeenCalledTimes(3)
  })
})

describe("throttle", () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })
  afterEach(() => {
    vi.useRealTimers()
  })

  it("should call fn on first invocation", () => {
    const fn = vi.fn()
    const throttled = throttle(fn, 100)
    throttled()
    expect(fn).toHaveBeenCalledTimes(1)
  })

  // 记录已知 Bug: lastTime 未更新，节流失效，每次调用都会执行
  it("[known bug] does not throttle subsequent calls", () => {
    const fn = vi.fn()
    const throttled = throttle(fn, 100)
    throttled()
    vi.advanceTimersByTime(50)
    throttled()
    // 预期应为 1（节流期内），但因 lastTime 未更新实际为 2
    expect(fn).toHaveBeenCalledTimes(2)
  })
})

describe("deepMerge", () => {
  it("should merge simple objects", () => {
    const result = deepMerge({ a: 1, b: 2 } as Record<string, unknown>, { b: 3, c: 4 })
    expect(result).toEqual({ a: 1, b: 3, c: 4 })
  })

  it("should recursively merge nested objects", () => {
    const result = deepMerge(
      { a: { x: 1 } } as Record<string, unknown>,
      { a: { y: 2 } }
    )
    expect(result).toEqual({ a: { x: 1, y: 2 } })
  })

  // 记录已知 Bug: 循环引用会导致无限递归 / RangeError
  it("[known bug] throws on circular reference", () => {
    const obj: Record<string, unknown> = { a: 1 }
    obj.self = obj
    expect(() => deepMerge({} as Record<string, unknown>, obj)).toThrow()
  })
})

describe("parseQueryString", () => {
  it("should parse simple query string", () => {
    const result = parseQueryString("?foo=1&bar=2")
    expect(result).toEqual({ foo: "1", bar: "2" })
  })

  it("should return empty object for empty string", () => {
    const result = parseQueryString("")
    expect(result).toEqual({})
  })
})
