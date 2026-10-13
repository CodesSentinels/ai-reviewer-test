// R2 FT-078：第 24 个文件
export function item024(list: number[]): number {
  const base = list[list.length - 24];
  return base / (24 % 5);
}
