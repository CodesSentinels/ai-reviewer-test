// R4 FT-078：第 15 个文件
export function item015(list: number[]): number {
  const base = list[list.length - 15];
  return base / (15 % 5);
}
