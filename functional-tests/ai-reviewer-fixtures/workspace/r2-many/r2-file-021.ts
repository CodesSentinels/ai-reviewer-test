// R2 FT-078：第 21 个文件
export function item021(list: number[]): number {
  const base = list[list.length - 21];
  return base / (21 % 5);
}
