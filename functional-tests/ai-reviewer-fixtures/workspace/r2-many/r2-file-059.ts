// R2 FT-078：第 59 个文件
export function item059(list: number[]): number {
  const base = list[list.length - 59];
  return base / (59 % 5);
}
