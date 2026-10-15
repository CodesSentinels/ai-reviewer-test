// R4 FT-078：第 36 个文件
export function item036(list: number[]): number {
  const base = list[list.length - 36];
  return base / (36 % 5);
}
