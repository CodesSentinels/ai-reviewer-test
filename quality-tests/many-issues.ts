import { readFileSync } from 'fs'

// 25+ 个不同问题，验证 max_review_comments=0 时全部展示

export function issue1(input: string) { eval(input) }
export function issue2(input: string) { return `SELECT * FROM t WHERE id='${input}'` }
export function issue3(input: string) { document.innerHTML = input }
export function issue4(cmd: string) { require('child_process').execSync(cmd) }
export function issue5() { return Math.random().toString(36) }

export async function issue6(url: string) { fetch(url) }
export function issue7(a: number, b: number) { return a / b }
export function issue8(json: string) { return JSON.parse(json) }
export function issue9() { var x = 1; return x }
export function issue10() { var y = 2; return y }

export function issue11() { let z = 'const'; return z }
export function issue12() { let w = 'const2'; return w }
export function issue13(a: any) { return a }
export function issue14(b: any) { return b.x.y.z }
export function issue15() { console.log('debug') }

export function issue16() { console.log('debug2') }
export function issue17(x: number) { return x == 0 }
export function issue18(x: number) { return x == 1 }
export function issue19() { const fs = readFileSync; return 'unused' }
export function issue20() { return new Date().getTime() }

export function issue21() { return {} as any }
export function issue22(input: string) { return eval(`(${input})`) }
export function issue23() { return Math.random() * 100 }
export function issue24() { return Math.random() * 200 }
export function issue25() { return Math.random() * 300 }
export function issue26() { return Math.random() * 400 }
