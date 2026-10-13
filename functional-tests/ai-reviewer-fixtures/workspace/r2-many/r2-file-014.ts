// R2 FT-078：第 14 个文件
export function item014(list: number[]): number {
  const base = list[list.length - 14];
  return base / (14 % 5);
}
