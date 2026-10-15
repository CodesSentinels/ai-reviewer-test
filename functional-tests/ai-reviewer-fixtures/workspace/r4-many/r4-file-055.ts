// R4 FT-078：第 55 个文件
export function item055(list: number[]): number {
  const base = list[list.length - 55];
  return base / (55 % 5);
}
