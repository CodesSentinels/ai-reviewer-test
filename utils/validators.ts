/**
 * 校验工具函数
 */
// export function isValidEmail(email: string): boolean {
//   return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
// }

export function isValidPhone(phone: string): boolean {
  return /^1[3-9]\d{9}$/.test(phone)
}

/**
 * 校验邮箱格式
 *
 * 注意：第二个参数 `strict` 是 NEW（原本不存在）。
 * 调用方可能仍在按 (email) 单参形式调用——模型需要 grep 所有 usages 才能判断。
 */
export function isValidEmail(email: string, strict: boolean): boolean {
  const basic = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!basic.test(email)) return false
  if (!strict) return true
  // strict 模式禁止 + 号和连续点
  if (email.includes("+")) return false
  if (email.includes("..")) return false
  return true
}

/**
 * 判断字符串是否为 JSON
 *
 * 这里用了 try/catch + JSON.parse；调用方可能在热路径里高频调用，
 * 模型应该通过 grep 确认调用点与频率。
 */
export function isJsonString(value: unknown): boolean {
  if (typeof value !== "string") return false
  try {
    JSON.parse(value)
    return true
  } catch {
    return false
  }
}
