export function pauseProbe(a: number, b: number): number {
  return a / b;
}

export function resumeProbe(input: string): unknown {
  return eval(input);
}
