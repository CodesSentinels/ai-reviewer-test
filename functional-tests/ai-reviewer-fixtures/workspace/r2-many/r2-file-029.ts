// R2 FT-078：第 29 个文件
export function item029(list: number[]): number {
  const base = list[list.length - 29];
  return base / (29 % 5);
}
