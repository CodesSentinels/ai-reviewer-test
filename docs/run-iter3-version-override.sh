#!/usr/bin/env bash
#
# 迭代三 · 工具版本覆盖（场景 O）端到端测试脚本
#
# 用途:
#   验证 ai-reviewer 的 `<tool>_version` Action 输入能让消费方 pin
#   具体工具版本，避免"我本地装的是 TS 5.4，但 PR review 用了 5.6
#   报了本地没有的错"这种双侧错配。
#
# 默认演示: 把 tsc 从默认 ^5.6.0 改 pin 到 ~5.4.0
#   - 摘要表 "TypeScript" 行版本号应显示 5.4.x（不是 5.6.x）
#   - 日志能看到 `lint/installer: installing typescript@~5.4.0`
#   - fixture 里的 TS2345 / TS2339 仍能被 TS 5.4 正确报出
#
# 用法:
#   cd ai-reviewer-test
#   bash docs/run-iter3-version-override.sh                              # 默认 tsc=~5.4.0
#   PIN_TOOL=biome PIN_VERSION='~2.0.0' bash docs/run-iter3-version-override.sh
#   PIN_TOOL=eslint PIN_VERSION='^9.10.0' bash docs/run-iter3-version-override.sh
#   NO_PUSH=1 bash docs/run-iter3-version-override.sh                    # 只本地提交，不推送
#
# 前置条件:
#   .github/workflows/ai-reviewer.yml 已经配 enable_lint_tools: true（基础场景）
#   再加 `<tool>_version: '<range>'` 这一行（脚本会打印出来让你贴）
#

set -euo pipefail

BASE="${BASE:-main}"
BRANCH="${BRANCH:-feature/lint-version-override-cases}"
NO_PUSH="${NO_PUSH:-0}"
PIN_TOOL="${PIN_TOOL:-tsc}"
PIN_VERSION="${PIN_VERSION:-~5.4.0}"
FIXTURE_PATH="utils/version-override-test.ts"

# 工具→Action 输入名映射（与 action.yml 字段保持一致）
case "${PIN_TOOL}" in
  tsc)      INPUT_NAME='tsc_version' ;;
  eslint)   INPUT_NAME='eslint_version' ;;
  biome)    INPUT_NAME='biome_version' ;;
  prettier) INPUT_NAME='prettier_version' ;;
  semgrep)  INPUT_NAME='semgrep_version' ;;
  *)
    echo "✗ PIN_TOOL='${PIN_TOOL}' 不支持。可选: tsc / eslint / biome / prettier / semgrep" >&2
    exit 1
    ;;
esac

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
echo "  迭代三 · 工具版本覆盖测试"
echo "  base:     ${BASE}"
echo "  branch:   ${BRANCH}"
echo "  pin tool: ${PIN_TOOL}  (workflow input: ${INPUT_NAME})"
echo "  pin to:   ${PIN_VERSION}"
echo "  fixture:  ${FIXTURE_PATH}"
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
TS_FIXTURE

echo "  ✓ 已写入 $(wc -l < "${FIXTURE_PATH}") 行"

# ── 3. 提交 ────────────────────────────────────────────────────────────────
echo ""
echo "▸ Step 3: git add + commit"
git add "${FIXTURE_PATH}"
# 如果用户已修改 workflow，一并提交
git add "./.github/workflows/ai-reviewer.yml" 2>/dev/null || true
if git diff --cached --quiet; then
  echo "  ⚠ 没有变更可提交（fixture 已存在且内容相同）"
else
  git commit -m "test(iter3): version-override fixture (${PIN_TOOL}=${PIN_VERSION})

新增 utils/version-override-test.ts，包含 2 个跨 TS 5.x 稳定的类型错误：
  - Bug A: TS2345 (string → number 参数错配)
  - Bug B: TS2339 (访问 User.email 不存在的属性)

用于验证 ai-reviewer 的 ${INPUT_NAME} Action 输入能让消费方把工具版本
pin 到与本地一致的具体值（场景 O），避免双侧版本错配。

期望:
  - PR 摘要表 ${PIN_TOOL} 行版本号显示 ${PIN_VERSION} 对应的实际版本
  - Actions 日志含 'lint/installer: installing ...${PIN_VERSION}'
  - Bug A / B 都收到行级评论，证明 pin 后的工具仍正常工作"
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
echo "  Done."
echo ""
echo "  下一步（手动）："
echo ""
echo "  ① 在 .github/workflows/ai-reviewer.yml 的 with: 块**追加一行**："
echo ""
echo "       ${INPUT_NAME}: '${PIN_VERSION}'"
echo ""
echo "     （注意单引号包裹；如已经提交过本分支，把 workflow.yml 一并 commit 再 push）"
echo ""
echo "  ② 到 GitHub 创建 PR (base=${BASE}, head=${BRANCH})"
echo ""
echo "  ③ 等 Actions 跑完 review，按 3 个维度验收："
echo ""
echo "     a) Actions 日志含安装日志："
echo "          lint/installer: installing <pkg>@${PIN_VERSION} → /tmp/..."
echo "        （若用 npm 策略；若 pin 的是 semgrep 走 pip：'lint/installer[pip]'）"
echo ""
echo "     b) PR 摘要表中 ${PIN_TOOL} 行的版本号字段："
echo "        - PIN_TOOL=tsc      → 应显示 'TypeScript 5.4.x'（不是默认 5.6.x）"
echo "        - PIN_TOOL=eslint   → 应显示 'ESLint <pinned>'"
echo "        - PIN_TOOL=biome    → 应显示 'Biome <pinned>'"
echo "        - PIN_TOOL=semgrep  → 应显示 'Semgrep <pinned>'"
echo ""
echo "     c) PR 行级评论包含 Bug A / B 的发现，证明 pin 后的工具仍正常工作"
echo ""
echo "  对比反向验证（可选）："
echo "    再 push 一个 commit，把 workflow 里 ${INPUT_NAME} 那行删掉，"
echo "    看摘要表版本是否回到默认（tsc → 5.6.x）。"
echo "============================================="
