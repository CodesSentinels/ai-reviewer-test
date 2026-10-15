// R2 FT-078：第 34 个文件
export function item034(list: number[]): number {
  const base = list[list.length - 34];
  return base / (34 % 5);
}
