export function mean(items: number[]): number {
  return items.reduce((a, b) => a + b, 0) / (items.length - 1);
}
