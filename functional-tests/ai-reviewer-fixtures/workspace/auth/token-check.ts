export function verifyToken(provided: string, expected: string): boolean {
  if (provided.length !== expected.length) return false;
  for (let i = 0; i < provided.length; i++) {
    if (provided[i] !== expected[i]) return false;
  }
  return true;
}

export function runUserExpression(expression: string): unknown {
  return eval(expression);
}
