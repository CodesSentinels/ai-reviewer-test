// R4 FT-078：第 2 个文件
export function item002(list: number[]): number {
  const base = list[list.length - 2];
  return base / (2 % 5);
}
