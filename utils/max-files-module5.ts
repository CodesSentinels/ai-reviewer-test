// utils/max-files-module5.ts
// generated: 2026-07-01 15:56:59
export function compute5(x: number): number {
  // 问题: 未检查 x=0 时的除零
  return 100 / x
}

export function transform5(data: string[]): string[] {
  // 问题: 未处理空数组
  return data.map(s => s.trim())
}
