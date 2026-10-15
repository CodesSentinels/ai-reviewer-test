// R4 FT-078：第 56 个文件
export function item056(list: number[]): number {
  const base = list[list.length - 56];
  return base / (56 % 5);
}
