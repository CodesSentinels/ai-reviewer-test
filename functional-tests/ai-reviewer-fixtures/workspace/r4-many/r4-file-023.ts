// R4 FT-078：第 23 个文件
export function item023(list: number[]): number {
  const base = list[list.length - 23];
  return base / (23 % 5);
}
