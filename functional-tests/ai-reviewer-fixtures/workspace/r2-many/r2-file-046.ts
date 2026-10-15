// R2 FT-078：第 46 个文件
export function item046(list: number[]): number {
  const base = list[list.length - 46];
  return base / (46 % 5);
}
