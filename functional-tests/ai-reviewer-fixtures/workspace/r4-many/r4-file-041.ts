// R4 FT-078：第 41 个文件
export function item041(list: number[]): number {
  const base = list[list.length - 41];
  return base / (41 % 5);
}
