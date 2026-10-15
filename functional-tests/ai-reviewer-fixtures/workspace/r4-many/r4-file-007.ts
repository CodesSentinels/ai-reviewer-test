// R4 FT-078：第 7 个文件
export function item007(list: number[]): number {
  const base = list[list.length - 7];
  return base / (7 % 5);
}
