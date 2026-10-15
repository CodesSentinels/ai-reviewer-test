// R2 FT-078：第 9 个文件
export function item009(list: number[]): number {
  const base = list[list.length - 9];
  return base / (9 % 5);
}
