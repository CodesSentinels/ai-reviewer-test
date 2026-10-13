// R4 FT-078：第 30 个文件
export function item030(list: number[]): number {
  const base = list[list.length - 30];
  return base / (30 % 5);
}
