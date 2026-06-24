/**
 * lint-test-eslint-biome.ts — 专攻 ESLint + Biome 的测试 fixture
 *
 * 与 lint-test-cart.ts 的区别：
 *   - lint-test-cart.ts 混合了 tsc 类型错误（Bug 8/9），主要用例是 tsc
 *   - 本文件**只放 ESLint / Biome 能直接抓到的非类型问题**，且每个
 *     bug 与下一个 bug 之间隔 ≥ 5 行，避免被 ±3 变更行窗口聚簇
 *
 * 验证目标：
 *   - PR 评论里能同时出现 ESLint 与 Biome 的发现（不再只有 tsc）
 *   - 跨工具去重：同一行同款问题不会被两条独立评论刷屏
 *   - 变更行过滤：本文件**整体**是新增 → 每条发现都进窗口
 *
 * 不要在生产代码中复制这些反模式。
 */

/* ────────────────────────────────────────────────────────────────────────
 * Bug 1：map 回调缺少 return
 *   - ESLint: array-callback-return
 *   - Biome:  lint/suspicious/useIterableCallbackReturn
 * ────────────────────────────────────────────────────────────────────── */
export function sumQuantities(items: ReadonlyArray<{qty: number}>): number {
  let total = 0
  items.map(item => {
    total += item.qty
  })
  return total
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 2：声明了从未使用的变量
 *   - ESLint: no-unused-vars
 *   - Biome:  lint/correctness/noUnusedVariables
 * ────────────────────────────────────────────────────────────────────── */
export function describeProduct(name: string): string {
  const tempDescription = 'reserved for future copy'
  return `Product: ${name}`
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 3：== 而非 ===
 *   - ESLint: eqeqeq
 *   - Biome:  lint/suspicious/noDoubleEquals
 * ────────────────────────────────────────────────────────────────────── */
export function isPlaceholderName(name: string): boolean {
  return name == 'placeholder'
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 4：生产代码不应保留 console.log
 *   - ESLint: no-console（warning）
 *   - Biome:  lint/suspicious/noConsole（recommended 2.x 默认 warn）
 * ────────────────────────────────────────────────────────────────────── */
export function debugUser(userId: string): void {
  console.log(`user looked up: ${userId}`)
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 5：var 而非 let/const
 *   - Biome:  lint/style/noVar（recommended）
 *   - ESLint: 项目配置未启用 no-var，仅 Biome 会报
 * ────────────────────────────────────────────────────────────────────── */
export function legacyCounter(): number {
  var count = 0
  count += 1
  return count
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 6：字符串拼接应使用模板字符串
 *   - Biome:  lint/style/useTemplate（recommended）
 *   - ESLint: 项目配置未启用 prefer-template，仅 Biome 会报
 * ────────────────────────────────────────────────────────────────────── */
export function greet(first: string, last: string): string {
  return 'hello ' + first + ' ' + last
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 7：let 但从未重新赋值，应改 const
 *   - Biome:  lint/style/useConst（recommended）
 *   - ESLint: 项目配置未启用 prefer-const，仅 Biome 会报
 * ────────────────────────────────────────────────────────────────────── */
export function pickSecondWord(sentence: string): string {
  let words = sentence.split(' ')
  return words[1] ?? ''
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 8：同一行同时被 ESLint + Biome 报告 —— 用来验证跨工具去重
 *   - ESLint: eqeqeq（同 Bug 3 的规则）
 *   - Biome:  lint/suspicious/noDoubleEquals（同 Bug 3 的规则）
 *
 * 期望：PR 评论里只出现 1 条评论，🧰 Tools 卡片同时列出 ESLint + Biome
 * ────────────────────────────────────────────────────────────────────── */
export function isEmptyish(value: unknown): boolean {
  return value == null || value == ''
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 9：第二次出现 array-callback-return —— 验证多发现都能进评论
 *   - 与 Bug 1 同款规则，但在不同函数 → 应独立报两条
 *   - 业务上：用 forEach 才是正解，map 应该用返回值
 * ────────────────────────────────────────────────────────────────────── */
export function priceLabels(prices: number[]): string[] {
  const labels: string[] = []
  prices.map(p => {
    labels.push(`¥${p.toFixed(2)}`)
  })
  return labels
}
