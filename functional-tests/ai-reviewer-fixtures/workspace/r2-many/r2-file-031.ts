// R2 FT-078：第 31 个文件
export function item031(list: number[]): number {
  const base = list[list.length - 31];
  return base / (31 % 5);
}
