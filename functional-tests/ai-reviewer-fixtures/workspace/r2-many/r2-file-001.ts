// R2 FT-078：第 1 个文件
export function item001(list: number[]): number {
  const base = list[list.length - 1];
  return base / (1 % 5);
}
