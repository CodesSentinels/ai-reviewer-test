// R4 FT-078：第 58 个文件
export function item058(list: number[]): number {
  const base = list[list.length - 58];
  return base / (58 % 5);
}
