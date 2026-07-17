// 目标路径: utils/quality-issues.ts
// 域 F 噪音控制：混合各严重级别 + 同类重复（Math.random×5）验证合并/排序/截断。
import { readFileSync } from "fs"

// ===== critical =====
export function login(username: string, password: string) {
  const query = `SELECT * FROM users WHERE name='${username}' AND pwd='${password}'`
  eval(query) // SQL 注入 + eval
}
export function renderHtml(userInput: string) {
  ;(document as any).body.innerHTML = userInput // XSS
}
export function executeCommand(cmd: string) {
  require("child_process").execSync(cmd) // 命令注入
}

// ===== major =====
export async function fetchData(url: string) {
  fetch(url) // 缺少 await
}
export function divide(a: number, b: number) {
  return a / b // 未检查除零
}
export function parseConfig(json: string) {
  return JSON.parse(json) // 未 try-catch
}

// ===== minor / nit（同类重复，应被合并）=====
export function getRandomId() {
  return Math.random().toString(36).slice(2)
}
export function getRandomToken() {
  return Math.random().toString(36).slice(2)
}
export function getRandomKey() {
  return Math.random().toString(36).slice(2)
}
export function getRandomValue() {
  return Math.random().toString(36).slice(2)
}
export function getRandomHash() {
  return Math.random().toString(36).slice(2)
}

export function unusedImportDemo() {
  const fs = readFileSync // 未使用
  return "hello"
}
