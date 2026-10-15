// R2 FT-078：第 6 个文件
export function item006(list: number[]): number {
  const base = list[list.length - 6];
  return base / (6 % 5);
}
