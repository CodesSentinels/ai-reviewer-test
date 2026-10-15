// R2 FT-078：第 40 个文件
export function item040(list: number[]): number {
  const base = list[list.length - 40];
  return base / (40 % 5);
}
