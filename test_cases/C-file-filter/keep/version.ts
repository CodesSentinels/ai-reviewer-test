// 目标路径: utils/version.ts
// 应被审查：匹配 path_filters 的 **/*.ts
export const VERSION = '1.0.0'

export function bug(x: number): number {
  return 100 / x // 未处理除零，作为「确实被审查」的信号
}
