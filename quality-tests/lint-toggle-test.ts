import { readFileSync } from 'fs'

// ESLint: no-unused-vars
const unusedVar = 'never used'

// ESLint: no-undef (intentional undeclared reference)
function callMissing() {
  // @ts-ignore
  return undeclaredFunction()
}

// tsc: TS2554 — wrong number of arguments (strict-independent)
function greet(name: string, age: number): string {
  return `${name} is ${age}`
}
const res = greet('Alice')

// Biome: noExplicitAny
export function anyType(x: any): any {
  return x.deep.access
}

// Biome: useConst
export function constTest() {
  let neverReassigned = 'hello'
  return neverReassigned
}
