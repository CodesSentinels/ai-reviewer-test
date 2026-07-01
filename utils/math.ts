// utils/math.ts
// generated: 2026-07-01 10:39:46
export function add(a: number, b: number): number {
  return a + b
}

export function multiply(a: number, b: number): number {
  return a * b
}

export function divide(a: number, b: number): number {
  return a / b  // 问题: 未检查除零（b=0 时返回 Infinity）
}

export function power(base: number, exp: number): number {
  // 问题: 负指数处理不当（exp < 0 时循环不执行，返回 1）
  let result = 1
  for (let i = 0; i < exp; i++) {
    result *= base
  }
  return result
}
