// R4 FT-078：第 11 个文件
export function item011(list: number[]): number {
  const base = list[list.length - 11];
  return base / (11 % 5);
}
