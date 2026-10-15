// R2 FT-078：第 25 个文件
export function item025(list: number[]): number {
  const base = list[list.length - 25];
  return base / (25 % 5);
}
