// R4 FT-078：第 27 个文件
export function item027(list: number[]): number {
  const base = list[list.length - 27];
  return base / (27 % 5);
}
