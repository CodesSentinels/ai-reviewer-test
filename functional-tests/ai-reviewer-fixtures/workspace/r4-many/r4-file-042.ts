// R4 FT-078：第 42 个文件
export function item042(list: number[]): number {
  const base = list[list.length - 42];
  return base / (42 % 5);
}
