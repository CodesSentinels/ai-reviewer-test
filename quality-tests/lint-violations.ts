import { readFileSync } from 'fs'

// ESLint: no-unused-vars（3.4.1）
const unusedVariable = 42

// ESLint: no-undef / tsc: TS2304（3.4.1 / 3.4.2）
function callUndefined() {
  return undeclaredFunction()
}

// tsc: TS2345 类型不匹配（3.4.2）
function expectNumber(n: number): number {
  return n * 2
}
const result = expectNumber("hello" as any as number)

// Biome: noExplicitAny（3.4.3）
export function unsafeAny(x: any): any {
  return x.foo.bar.baz
}

// Biome: useConst（3.4.3）
export function shouldUseConst() {
  let value = 'never reassigned'
  return value
}
