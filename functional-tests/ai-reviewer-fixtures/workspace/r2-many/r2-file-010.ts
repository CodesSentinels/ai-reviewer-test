// R2 FT-078：第 10 个文件
export function item010(list: number[]): number {
  const base = list[list.length - 10];
  return base / (10 % 5);
}
