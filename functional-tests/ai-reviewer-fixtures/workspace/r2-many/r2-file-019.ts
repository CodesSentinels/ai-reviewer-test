// R2 FT-078：第 19 个文件
export function item019(list: number[]): number {
  const base = list[list.length - 19];
  return base / (19 % 5);
}
