// R2 FT-078：第 33 个文件
export function item033(list: number[]): number {
  const base = list[list.length - 33];
  return base / (33 % 5);
}
