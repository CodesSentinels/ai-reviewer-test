// R2 FT-078：第 50 个文件
export function item050(list: number[]): number {
  const base = list[list.length - 50];
  return base / (50 % 5);
}
