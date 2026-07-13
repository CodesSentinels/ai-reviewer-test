export function add(a: number, b: number): number {
  return a + b
}

export function multiply(a: number, b: number): number {
  return a * b
}

export function divide(a: number, b: number): number {
  return a / b // 问题：未检查除零
}

export function power(base: number, exp: number): number {
  let result = 1
  for (let i = 0; i < exp; i++) {
    result *= base // 问题：负指数处理不当
  }
  return result
}
