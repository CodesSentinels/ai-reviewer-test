export function sumPositive(list: number[]): number {
  return list.filter((x) => x > 0).reduce((a, b) => a + b);
}
