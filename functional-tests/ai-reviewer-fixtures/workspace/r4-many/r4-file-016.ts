// R4 FT-078：第 16 个文件
export function item016(list: number[]): number {
  const base = list[list.length - 16];
  return base / (16 % 5);
}
