// R4 FT-078：第 32 个文件
export function item032(list: number[]): number {
  const base = list[list.length - 32];
  return base / (32 % 5);
}
