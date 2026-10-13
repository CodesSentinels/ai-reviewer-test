// R2 FT-078：第 52 个文件
export function item052(list: number[]): number {
  const base = list[list.length - 52];
  return base / (52 % 5);
}
