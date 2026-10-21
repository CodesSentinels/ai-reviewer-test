export function unignoredFn(items: number[]): number {
  return items.reduce((a, b) => a + b) / items.length;
}
