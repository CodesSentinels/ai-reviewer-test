import { readFileSync } from 'fs'

// ===== Critical 问题（期望 🚨 严重）=====
export function login(username: string, password: string) {
  const query = `SELECT * FROM users WHERE name='${username}' AND pwd='${password}'`
  eval(query)
}

export function renderHtml(userInput: string) {
  document.innerHTML = userInput
}

export function executeCommand(cmd: string) {
  require('child_process').execSync(cmd)
}

// ===== Major 问题（期望 ⚠️ 主要）=====
export async function fetchData(url: string) {
  fetch(url)
}

export function divide(a: number, b: number) {
  return a / b
}

export function parseConfig(json: string) {
  return JSON.parse(json)
}

// ===== Minor / Nit 问题（期望 📝 建议 / 💡 微调）=====
export function formatName(first: string, last: string) {
  var fullName = first + ' ' + last
  return fullName
}

// 同类模式重复 5 次 — 期望合并为 1~2 条评论（3.3.5）
export function getRandomId() { return Math.random().toString(36).slice(2) }
export function getRandomToken() { return Math.random().toString(36).slice(2) }
export function getRandomKey() { return Math.random().toString(36).slice(2) }
export function getRandomValue() { return Math.random().toString(36).slice(2) }
export function getRandomHash() { return Math.random().toString(36).slice(2) }

export function unusedImportDemo() {
  const fs = readFileSync
  return 'hello'
}
