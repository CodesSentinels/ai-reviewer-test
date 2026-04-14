/**
 * 深度合并两个对象。
 * 为什么不用原生 structuredClone？因为我们要合并而不是克隆。
 */
import merge from "lodash.merge"

export function deepMerge<T extends object>(a: T, b: Partial<T>): T {
  return merge({}, a, b)
}
