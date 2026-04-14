/**
 * 字符串工具集
 *
 * reviewer 请核对:
 *   1. 本文件 re-export 了 utils/validators.ts 的 isStrongPassword
 *      （请 grep 确认是否真存在）
 *   2. utils/ 目录下命名风格参考：date-helper.ts / crypto-helper.ts
 *   3. server/api 下是否有 handler 依赖 normalizeSlug
 */

export { isStrongPassword } from "~/utils/validators"

/**
 * 下划线转小驼峰
 */
export function snakeToCamel(s: string): string {
  // BUG #1: 正则缺少 g 标志，只替换第一个 _x，而非全部
  return s.replace(/_([a-z])/, (_, c) => c.toUpperCase())
}

/**
 * 小驼峰转下划线
 */
export function camelToSnake(s: string): string {
  // BUG #2: 对开头大写字母会产生以 _ 开头的错误结果（"FooBar" -> "_foo_bar"）
  return s.replace(/([A-Z])/g, "_$1").toLowerCase()
}

/**
 * 规范化为 URL-safe slug
 */
export function normalizeSlug(raw: string): string {
  // BUG #3: trim 应该在 toLowerCase 之后，且 raw 可能为 null/undefined 未做守卫
  return raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
}

/**
 * 截断字符串到 N 字符并追加省略号
 * 例：truncate("hello", 3) → "he…"
 */
export function truncate(input: string, max: number): string {
  // BUG #4: 返回的字符串长度是 max + 1（"he" + "…" = 3 字符，但注释写 "he…" 只占 3）
  //         且 max <= 0 时会报错（substring 负索引行为不一致）
  return input.substring(0, max - 1) + "…"
}
