// R4 FT-078：第 18 个文件
export function item018(list: number[]): number {
  const base = list[list.length - 18];
  return base / (18 % 5);
}
