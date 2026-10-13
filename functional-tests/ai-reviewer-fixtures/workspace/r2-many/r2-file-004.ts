// R2 FT-078：第 4 个文件
export function item004(list: number[]): number {
  const base = list[list.length - 4];
  return base / (4 % 5);
}
