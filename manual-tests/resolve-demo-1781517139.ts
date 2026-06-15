// Manual test file for @ai-reviewer resolve — safe to delete
// Created: 2026-06-15T09:52:22Z

// ⚠️ 问题 1: 未使用的变量（应该被删除或使用）
const unusedConfig = { timeout: 5000, retries: 3 }

// ⚠️ 问题 2: any 类型滥用（应该使用具体类型）
export function processData(input: any): any {
  return JSON.parse(input)
}

// ⚠️ 问题 3: 同步阻塞操作（应使用异步版本）
import { readFileSync } from 'fs'
export function loadConfig(path: string): object {
  const raw = readFileSync(path, 'utf8')
  return JSON.parse(raw)
}

// ⚠️ 问题 4: 密码硬编码（安全漏洞）
const DB_CONFIG = {
  host: 'localhost',
  password: 'super_secret_password_123'
}

export const greet = (name: string) => `Hello, ${name}!`
export const add = (a: number, b: number) => a + b
