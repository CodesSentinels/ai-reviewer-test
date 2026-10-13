// R2 FT-078：第 22 个文件
export function item022(list: number[]): number {
  const base = list[list.length - 22];
  return base / (22 % 5);
}
