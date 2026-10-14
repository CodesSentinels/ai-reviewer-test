export function runCode(input: string): unknown {
  return eval(input);
}

export function ratio(a: number, b: number): number {
  return a / b;
}

export function doubleAll(list: number[]): number[] {
  return list.map((x) => {
    x * 2;
  });
}

export const user_name = "ada";
