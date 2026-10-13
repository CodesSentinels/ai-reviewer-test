// R2 FT-078：第 3 个文件
export function item003(list: number[]): number {
  const base = list[list.length - 3];
  return base / (3 % 5);
}
