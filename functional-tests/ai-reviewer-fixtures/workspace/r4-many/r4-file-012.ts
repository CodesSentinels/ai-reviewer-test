// R4 FT-078：第 12 个文件
export function item012(list: number[]): number {
  const base = list[list.length - 12];
  return base / (12 % 5);
}
