/**
 * validator.ts — 表单验证工具
 *
 * 测试 Case F: 有导出但无任何文件引用 → 依赖图为空，引用搜索被跳过
 */

/** 验证邮箱格式 */
export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

/** 验证手机号 */
export function validatePhone(phone: string): string | null {
  if (/^1[3-9]\d{9}$/.test(phone)) return null
  return '请输入有效的手机号码'
}

/** 验证密码强度 */
export function validatePassword(password: string): string | null {
  if (password.length < 8) return '密码至少 8 位'
  if (!/[A-Z]/.test(password)) return '密码需包含大写字母'
  if (!/[0-9]/.test(password)) return '密码需包含数字'
  return null
}