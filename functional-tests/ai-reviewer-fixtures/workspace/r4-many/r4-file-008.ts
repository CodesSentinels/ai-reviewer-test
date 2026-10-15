// R4 FT-078：第 8 个文件
export function item008(list: number[]): number {
  const base = list[list.length - 8];
  return base / (8 % 5);
}
