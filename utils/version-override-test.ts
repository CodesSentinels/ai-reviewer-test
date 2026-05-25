/**
 * version-override-test.ts — 验证 ai-reviewer 的 `<tool>_version` 覆盖机制
 *
 * 触发两个**跨 TS 5.x 全部稳定**的类型错误，无论 tsc 装的是 5.4 / 5.5 / 5.6
 * 都能复现，便于验证：
 *
 *   1. workflow 里 `tsc_version: '~5.4.0'` 真的让 ai-reviewer 装到 5.4.x
 *   2. PR 摘要表显示的版本号是 5.4.x 而非默认 5.6.x
 *   3. 装的版本仍能正常类型检查
 *
 * 与 lint-test-cart.ts 中 Bug 8/9 重叠是有意的 —— 把"版本覆盖测试"独立
 * 出一个 PR 避免和 ESLint/Biome 测试混在一起，PR 摘要表对比更直观。
 */

interface User {
  id: string
  name: string
}

/* ──────────────────────────────────────────────────────────────────────
 * Bug A：TS2345 — 实参类型不匹配
 *   传 string 给声明为 number 的参数；tsc 5.x 全版本都报
 * ────────────────────────────────────────────────────────────────────── */
export function getUserById(id: number): User {
  return {id: id.toString(), name: 'demo'}
}

const _user = getUserById('abc')


/* ──────────────────────────────────────────────────────────────────────
 * Bug B：TS2339 — 访问不存在的属性
 *   User 上没有 email 字段；tsc 全版本都报
 * ────────────────────────────────────────────────────────────────────── */
export function describeUser(u: User): string {
  return `email=${u.email}`
}

export const _demoDescribe = describeUser({id: '1', name: 'demo'})
