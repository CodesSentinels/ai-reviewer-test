/** 通用校验工具，被 composables/useAuth 与页面表单引用。 */
export function isEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
}

export function isNonEmpty(value: string): boolean {
  return value.trim().length > 0
}

export function isInRange(n: number, min: number, max: number): boolean {
  return n >= min && n <= max
}
