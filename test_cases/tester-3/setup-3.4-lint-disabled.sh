#!/usr/bin/env bash
#
# setup-3.4-lint-disabled.sh — 准备 3.4.5 / 3.4.6 Lint 开关场景
#
# 验证项目:
#   3.4.5 enable_lint_tools: false → 无 lint 相关内容
#   3.4.6 单独禁用某工具 → 该工具不运行
#
# 前置条件:
#   ⚠️ 需要先手动修改 .github/workflows/ai-reviewer.yml
#   测试 3.4.5: 设置 enable_lint_tools: false
#   测试 3.4.6: 设置 enable_eslint: false（保持其他 lint 工具开启）
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-3/setup-3.4-lint-disabled.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  SECRETS_FILE="$REPO_ROOT/.secrets"
  if [[ -f "$SECRETS_FILE" ]]; then
    export GITHUB_TOKEN="$(grep '^GITHUB_TOKEN=' "$SECRETS_FILE" | cut -d= -f2)"
  fi
fi
export GH_TOKEN="$GITHUB_TOKEN"

BASE_BRANCH="test/dev4"

echo "================================================================"
echo "  场景: 3.4.5 / 3.4.6 Lint 开关验证"
echo "================================================================"
echo ""
echo "请选择测试模式:"
echo "  1) 3.4.5 — enable_lint_tools: false（全部关闭）"
echo "  2) 3.4.6 — enable_eslint: false（仅关 ESLint）"
echo ""
read -p "选择 (1/2): " choice

case "$choice" in
  1)
    TEST_ID="3.4.5"
    BRANCH="test/tester3-nolint-$(date +%m%d-%H%M)"
    TITLE="[TEST 3.4.5] enable_lint_tools=false 验证"
    EXPECT="评论中无任何 lint 规则引用、无 🧰 Tools 卡片"
    ;;
  2)
    TEST_ID="3.4.6"
    BRANCH="test/tester3-noeslint-$(date +%m%d-%H%M)"
    TITLE="[TEST 3.4.6] enable_eslint=false 验证"
    EXPECT="无 ESLint 规则引用，但 tsc/Biome 仍有"
    ;;
  *)
    echo "无效选择"; exit 1 ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚠️  请确认已修改 .github/workflows/ai-reviewer.yml"
echo "  测试 ${TEST_ID}: 预期 — ${EXPECT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "已确认修改 workflow 配置? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "请先修改 workflow 配置后再运行本脚本。"
  exit 1
fi

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

mkdir -p quality-tests

# 复用 lint-violations.ts 代码 — 含 ESLint + tsc + Biome 问题
echo "==> 写入 quality-tests/lint-toggle-test.ts（lint 开关验证）"
cat > quality-tests/lint-toggle-test.ts << 'EOF'
import { readFileSync } from 'fs'

// ESLint: no-unused-vars
const unusedVar = 'never used'

// ESLint: no-undef
function callMissing() {
  return missingFunction()
}

// tsc: TS2345 类型不匹配
function needsNumber(n: number): number {
  return n * 2
}
const res = needsNumber("text" as any as number)

// Biome: noExplicitAny
export function anyType(x: any): any {
  return x.deep.access
}

// Biome: useConst
export function constTest() {
  let neverReassigned = 'hello'
  return neverReassigned
}
EOF

git add quality-tests/lint-toggle-test.ts
git commit -m "test: add lint toggle test (tester 3 — ${TEST_ID})"

git push -u origin "$BRANCH"

PR_URL=$(gh pr create \
  --title "$TITLE" \
  --base "$BASE_BRANCH" \
  --body "$(cat << BODY
## 目的

验证 Lint 开关配置 (${TEST_ID})。

## 当前配置

测试 ${TEST_ID}

## 代码改动

\`quality-tests/lint-toggle-test.ts\` — 含 ESLint + tsc + Biome 可检测问题

## 预期 Bot 行为

- ${EXPECT}

## 测试完成后

⚠️ 恢复 workflow 配置!
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (${TEST_ID}): ${PR_URL}"
echo "================================================================"
echo ""
echo "验证: ${EXPECT}"
echo ""
echo "⚠️  测试完成后恢复 workflow lint 配置!"
