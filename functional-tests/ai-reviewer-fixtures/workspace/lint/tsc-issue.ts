export const count: number = "not-a-number";

export function add(a: number, b: number): number {
  return a + b + missingValue;
}
