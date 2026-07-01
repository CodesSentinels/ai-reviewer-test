// utils/max-files-module6.ts
// generated: 2026-07-01 15:56:59
export function compute6(x: number): number {
  // 问题: 未检查 x=0 时的除零
  return 100 / x
}

export function transform6(data: string[]): string[] {
  // 问题: 未处理空数组
  return data.map(s => s.trim())
}
