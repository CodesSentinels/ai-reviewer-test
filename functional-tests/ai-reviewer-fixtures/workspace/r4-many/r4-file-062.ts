// R4 FT-078：第 62 个文件
export function item062(list: number[]): number {
  const base = list[list.length - 62];
  return base / (62 % 5);
}
