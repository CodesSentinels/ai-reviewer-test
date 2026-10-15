// R4 FT-078：第 48 个文件
export function item048(list: number[]): number {
  const base = list[list.length - 48];
  return base / (48 % 5);
}
