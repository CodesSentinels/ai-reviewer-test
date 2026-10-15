// R4 FT-078：第 51 个文件
export function item051(list: number[]): number {
  const base = list[list.length - 51];
  return base / (51 % 5);
}
