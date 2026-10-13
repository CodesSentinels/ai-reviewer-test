// R2 FT-078：第 20 个文件
export function item020(list: number[]): number {
  const base = list[list.length - 20];
  return base / (20 % 5);
}
