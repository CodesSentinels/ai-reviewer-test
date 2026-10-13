// R2 FT-078：第 35 个文件
export function item035(list: number[]): number {
  const base = list[list.length - 35];
  return base / (35 % 5);
}
