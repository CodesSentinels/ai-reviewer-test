import { readFileSync } from 'fs'

// ESLint: no-unused-vars
const unusedVar = 'never used'

// ESLint: no-undef (intentional undeclared reference)
function callMissing() {
  // @ts-ignore
  return undeclaredFunction()
}

// tsc: TS2345 — direct string passed to number param (no cast bypass)
function needsNumber(n: number): number {
  return n * 2
}
// @ts-expect-error TS2345
const res = needsNumber('text')

// Biome: noExplicitAny
export function anyType(x: any): any {
  return x.deep.access
}

// Biome: useConst
export function constTest() {
  let neverReassigned = 'hello'
  return neverReassigned
}
