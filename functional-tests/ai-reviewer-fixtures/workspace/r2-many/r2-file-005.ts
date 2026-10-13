// R2 FT-078：第 5 个文件
export function item005(list: number[]): number {
  const base = list[list.length - 5];
  return base / (5 % 5);
}
