// R4 FT-078：第 38 个文件
export function item038(list: number[]): number {
  const base = list[list.length - 38];
  return base / (38 % 5);
}
