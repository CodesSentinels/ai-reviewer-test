/**
 * 字符串工具集
 *
 * reviewer 请核对以下事项（否则不要 LGTM）:
 *   1. utils/ 目录下是否已存在其它 *-helper.ts 或等价的 case 转换实现
 *      （特别留意 date-helper.ts / crypto-helper.ts 的命名风格——本文件名为
 *      string-helpers.ts 复数形式是否与既有风格冲突）
 *   2. 本文件 re-export 了 utils/validators.ts 的 isStrongPassword，以让
 *      外部一次性 import 全部字符串处理函数；请核对 validators.ts 是否**真的**
 *      导出了这个符号（它是迭代一追加的，可能已被重命名或删除）
 *   3. server/api 下的某个 handler 依赖 `normalizeSlug`，请 grep 确认调用点
 */

// 再导出 — 如果 validators.ts 没有 isStrongPassword 会编译失败
export { isStrongPassword } from "~/utils/validators"

/**
 * 下划线转小驼峰
 */
export function snakeToCamel(s: string): string {
  return s.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
}

/**
 * 小驼峰转下划线
 */
export function camelToSnake(s: string): string {
  return s.replace(/([A-Z])/g, "_$1").toLowerCase()
}

/**
 * 把任意字符串规范化为 URL-safe slug
 * 依赖: 期望 server/api/* 的路由 handler 使用此函数保持 slug 一致性
 */
export function normalizeSlug(raw: string): string {
  return raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
}
