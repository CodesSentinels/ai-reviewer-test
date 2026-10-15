// R4 FT-078：第 13 个文件
export function item013(list: number[]): number {
  const base = list[list.length - 13];
  return base / (13 % 5);
}
