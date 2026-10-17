export function avg(list: number[]): number {
  return list.reduce((x, y) => x + y, 0) / list.length;
}
