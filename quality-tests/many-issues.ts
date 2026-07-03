import { readFileSync } from 'fs'

// 26 个不同问题，验证 max_review_comments=0 时全部展示

// critical: eval 注入
export function issue1(input: string) { eval(input) }
// critical: SQL 拼接
export function issue2(input: string) { return `SELECT * FROM t WHERE id='${input}'` }
// critical: 命令注入
export function issue4(cmd: string) { require('child_process').execSync(cmd) }
// critical: 二次 eval
export function issue22(input: string) { return eval(`(${input})`) }

// major: 未 await
export async function issue6(url: string) { fetch(url) }
// major: 除零
export function issue7(a: number, b: number) { return a / b }
// major: JSON.parse 无 try-catch
export function issue8(json: string) { return JSON.parse(json) }

// minor: var 声明 x5
export function issue9() { var x = 1; return x }
export function issue10() { var y = 2; return y }
export function issue9b() { var a = 3; return a }
export function issue9c() { var b = 4; return b }
export function issue9d() { var c = 5; return c }

// minor: let 可改 const x2
export function issue11() { let z = 'const'; return z }
export function issue12() { let w = 'const2'; return w }

// minor: any 类型 x2
export function issue13(a: any) { return a }
export function issue14(b: any) { return b.x.y.z }

// nit: console.log x2
export function issue15() { console.log('debug') }
export function issue16() { console.log('debug2') }

// nit: == 而非 === x2
export function issue17(x: number) { return x == 0 }
export function issue18(x: number) { return x == 1 }

// nit: unused import 引用
export function issue19() { const fs = readFileSync; return 'unused' }

// nit: Math.random 弱随机 x5（期望合并）
export function issue5() { return Math.random().toString(36) }
export function issue23() { return Math.random() * 100 }
export function issue24() { return Math.random() * 200 }
export function issue25() { return Math.random() * 300 }
export function issue26() { return Math.random() * 400 }
