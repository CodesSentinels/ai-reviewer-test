// 目标路径: utils/lint-violations.ts
// 域 G：触发 ESLint / tsc / Biome 多工具。预期 Bot 评论引用工具规则 + 底部「🧰 Tools」卡片。
import {readFileSync} from 'fs'

const unusedVariable = 42 // ESLint no-unused-vars

function callUndefined() {
  return undeclaredFunction() // tsc TS2304 / ESLint no-undef
}

function expectNumber(n: number): number {
  return n * 2
}
const result = expectNumber('hello' as any as number) // tsc 类型不匹配

export function unsafeAny(x: any): any {
  return x.foo.bar.baz // Biome noExplicitAny
}

export function shouldUseConst() {
  let value = 'never reassigned' // Biome useConst / ESLint prefer-const
  return value
}

void callUndefined
void result
void readFileSync
