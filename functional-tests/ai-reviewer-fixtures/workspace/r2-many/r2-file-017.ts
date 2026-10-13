// R2 FT-078：第 17 个文件
export function item017(list: number[]): number {
  const base = list[list.length - 17];
  return base / (17 % 5);
}
