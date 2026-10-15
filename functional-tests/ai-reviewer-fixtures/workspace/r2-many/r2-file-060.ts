// R2 FT-078：第 60 个文件
export function item060(list: number[]): number {
  const base = list[list.length - 60];
  return base / (60 % 5);
}
