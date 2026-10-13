// R4 FT-078：第 28 个文件
export function item028(list: number[]): number {
  const base = list[list.length - 28];
  return base / (28 % 5);
}
