// R2 FT-078：第 61 个文件
export function item061(list: number[]): number {
  const base = list[list.length - 61];
  return base / (61 % 5);
}
