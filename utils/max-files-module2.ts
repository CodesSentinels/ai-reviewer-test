// utils/max-files-module2.ts
// generated: 2026-07-01 15:32:22
export function compute2(x: number): number {
  // 问题: 未检查 x=0 时的除零
  return 100 / x
}

export function transform2(data: string[]): string[] {
  // 问题: 未处理空数组
  return data.map(s => s.trim())
}
