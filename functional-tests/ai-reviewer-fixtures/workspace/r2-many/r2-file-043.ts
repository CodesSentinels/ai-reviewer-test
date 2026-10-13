// R2 FT-078：第 43 个文件
export function item043(list: number[]): number {
  const base = list[list.length - 43];
  return base / (43 % 5);
}
