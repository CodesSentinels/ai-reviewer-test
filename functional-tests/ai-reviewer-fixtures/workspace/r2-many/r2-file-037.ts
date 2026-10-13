// R2 FT-078：第 37 个文件
export function item037(list: number[]): number {
  const base = list[list.length - 37];
  return base / (37 % 5);
}
