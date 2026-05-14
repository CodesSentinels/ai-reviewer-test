#!/usr/bin/env bash
#
# 迭代三 · 专攻 ESLint + Biome 的测试 fixture 生成脚本
#
# 背景:
#   之前 feature/lint 上的 lint-test-cart.ts 已合并到分支 HEAD 一段时间，
#   后续 commit 只动了文件末尾的 tsc 用例（Bug 8/9），导致 ESLint/Biome
#   的发现行号都不在"本次 PR 的变更行 ± 3"窗口内 → 统计表显示
#   `ESLint 0/1`、`Biome 0/3`（项目里有问题，但没进评论）。
#
#   本脚本通过**新建分支 + 新建文件**，让整份测试文件的每一行都是
#   "本次 PR 新增"，所有 ESLint/Biome 发现都能落进 PR 评论。
#
#   脚本**只创建测试文件 + 提交 + 推送**，PR 请手动在 GitHub Web UI 创建。
#
# 用法:
#   cd ai-reviewer-test
#   bash docs/run-iter3-lint-eslint-biome.sh                       # 默认从 main 派生新分支
#   BASE=main bash docs/run-iter3-lint-eslint-biome.sh             # 显式指定 base
#   BRANCH=feature/my-lint-test bash docs/run-iter3-lint-eslint-biome.sh
#   NO_PUSH=1 bash docs/run-iter3-lint-eslint-biome.sh             # 只本地提交，不推送
#

set -euo pipefail

BASE="${BASE:-main}"
BRANCH="${BRANCH:-feature/lint-eslint-biome-cases}"
NO_PUSH="${NO_PUSH:-0}"
FIXTURE_PATH="utils/lint-test-eslint-biome.ts"

# ── 健壮性检查 ──────────────────────────────────────────────────────────────
if [[ ! -f package.json ]] || ! grep -q '"name"' package.json; then
  echo "✗ 必须在 ai-reviewer-test 仓库根目录运行" >&2
  exit 1
fi
if [[ ! -d .git ]]; then
  echo "✗ 当前目录不是 git 仓库" >&2
  exit 1
fi

echo "============================================="
echo "  迭代三 · ESLint + Biome 集成测试（fresh-file 方案）"
echo "  base:   ${BASE}"
echo "  branch: ${BRANCH}"
echo "  fixture:${FIXTURE_PATH}"
echo "============================================="

# ── 1. 切到新分支 ──────────────────────────────────────────────────────────
echo ""
echo "▸ Step 1: 从 ${BASE} 派生新分支 ${BRANCH}"
git fetch origin "${BASE}" --quiet || true
if git show-ref --quiet "refs/heads/${BRANCH}"; then
  echo "  分支已存在，切过去并重置到 origin/${BASE}（避免历史包袱）"
  git checkout "${BRANCH}"
  git reset --hard "origin/${BASE}"
else
  git checkout -b "${BRANCH}" "origin/${BASE}"
fi

# ── 2. 写入 fixture 文件 ───────────────────────────────────────────────────
echo ""
echo "▸ Step 2: 写入 ${FIXTURE_PATH}"
mkdir -p "$(dirname "${FIXTURE_PATH}")"
cat > "${FIXTURE_PATH}" <<'TS_FIXTURE'
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
TS_FIXTURE

echo "  ✓ 已写入 $(wc -l < "${FIXTURE_PATH}") 行"

# ── 3. 提交 ────────────────────────────────────────────────────────────────
echo ""
echo "▸ Step 3: git add + commit"
git add "${FIXTURE_PATH}"
if git diff --cached --quiet; then
  echo "  ⚠ 没有变更可提交（fixture 已经存在且内容相同）"
else
  git commit -m "test(iter3): add ESLint + Biome focused fixture

新增 utils/lint-test-eslint-biome.ts，包含 9 条专门为 ESLint/Biome 设计
的违规，每条间隔 ≥ 5 行避免被变更行窗口聚簇。期望 PR 评论中能同时
出现 ESLint + Biome 的发现（之前 0/N 的问题：lint-test-cart.ts 在
feature/lint 上已存在多 commit，bug 行不再是变更行）。

预期发现:
  - ESLint: array-callback-return ×2, no-unused-vars, eqeqeq ×2,
            no-console
  - Biome:  useIterableCallbackReturn ×2, noUnusedVariables,
            noDoubleEquals ×2, noVar, useTemplate, useConst, noConsole
  - 跨工具去重: Bug 3/8 同时被两侧报，应合并为单条评论"
fi

# ── 4. 推送 ────────────────────────────────────────────────────────────────
if [[ "${NO_PUSH}" == "1" ]]; then
  echo ""
  echo "▸ NO_PUSH=1，跳过推送"
  echo "  手动 push: git push -u origin ${BRANCH}"
else
  echo ""
  echo "▸ Step 4: 推送到远端"
  git push -u origin "${BRANCH}" --force-with-lease
fi

echo ""
echo "============================================="
echo "  Done. 请到 GitHub 手动创建 PR（base=${BASE}, head=${BRANCH}）"
echo "  PR 创建后等 GitHub Actions 跑完 review，观察统计表 + 行级评论。"
echo "============================================="
