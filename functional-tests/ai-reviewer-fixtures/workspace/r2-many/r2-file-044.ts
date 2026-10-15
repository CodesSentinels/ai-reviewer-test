// R2 FT-078：第 44 个文件
export function item044(list: number[]): number {
  const base = list[list.length - 44];
  return base / (44 % 5);
}
