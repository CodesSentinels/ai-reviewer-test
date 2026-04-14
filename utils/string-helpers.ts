/**
 * 把蛇形下划线转换为小驼峰。
 *
 * 注意：项目里可能已经有同名或同义工具，引入前请检查。
 */
export function snakeToCamel(s: string): string {
  return s.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
}

export function camelToSnake(s: string): string {
  return s.replace(/([A-Z])/g, "_$1").toLowerCase()
}
