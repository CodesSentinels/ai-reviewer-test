// R2 FT-078：第 26 个文件
export function item026(list: number[]): number {
  const base = list[list.length - 26];
  return base / (26 % 5);
}
