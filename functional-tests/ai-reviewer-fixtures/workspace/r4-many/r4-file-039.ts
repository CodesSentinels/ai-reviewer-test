// R4 FT-078：第 39 个文件
export function item039(list: number[]): number {
  const base = list[list.length - 39];
  return base / (39 % 5);
}
