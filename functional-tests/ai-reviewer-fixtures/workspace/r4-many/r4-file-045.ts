// R4 FT-078：第 45 个文件
export function item045(list: number[]): number {
  const base = list[list.length - 45];
  return base / (45 % 5);
}
