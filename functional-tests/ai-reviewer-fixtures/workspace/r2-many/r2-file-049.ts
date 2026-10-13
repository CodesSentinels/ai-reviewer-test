// R2 FT-078：第 49 个文件
export function item049(list: number[]): number {
  const base = list[list.length - 49];
  return base / (49 % 5);
}
