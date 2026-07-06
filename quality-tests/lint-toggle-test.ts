import { readFileSync } from 'fs'

// ESLint: no-unused-vars
const unusedVar = 'never used'

// ESLint: no-undef
function callMissing() {
  return (globalThis as any).missingFunction()
}

// tsc: TS2345 类型不匹配
function needsNumber(n: number): number {
  return n * 2
}
const res = needsNumber('text' as any as number)

// Biome: noExplicitAny
export function anyType(x: any): any {
  return x.deep.access
}

// Biome: useConst
export function constTest() {
  let neverReassigned = 'hello'
  return neverReassigned
}
