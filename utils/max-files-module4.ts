// utils/max-files-module4.ts
// generated: 2026-07-01 15:32:22
export function compute4(x: number): number {
  // 问题: 未检查 x=0 时的除零
  return 100 / x
}

export function transform4(data: string[]): string[] {
  // 问题: 未处理空数组
  return data.map(s => s.trim())
}
