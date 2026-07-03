#!/usr/bin/env bash
#
# setup-3.6-disabled.sh — 准备 3.6.3 / 3.6.4 Web 搜索与 Shell 关闭场景
#
# 验证项目:
#   3.6.3 enable_web_search: false → Actions 日志无 web_search 步骤
#   3.6.4 enable_shell: false → Actions 日志无 shell 步骤
#
# 前置条件:
#   ⚠️ 需要先手动修改 .github/workflows/ai-reviewer.yml
#   测试 3.6.3: 设置 enable_web_search: false
#   测试 3.6.4: 设置 enable_shell: false
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-3/setup-3.6-disabled.sh
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
echo "  场景: 3.6.3 / 3.6.4 Web 搜索 + Shell 关闭验证"
echo "================================================================"
echo ""
echo "请选择测试模式:"
echo "  1) 3.6.3 — enable_web_search: false"
echo "  2) 3.6.4 — enable_shell: false"
echo "  3) 两者同时关闭"
echo ""
read -p "选择 (1/2/3): " choice

case "$choice" in
  1)
    TEST_ID="3.6.3"
    BRANCH="test/tester3-noweb-$(date +%m%d-%H%M)"
    TITLE="[TEST 3.6.3] enable_web_search=false 验证"
    EXPECT="Actions 日志无 [web_search_debug] 记录"
    ;;
  2)
    TEST_ID="3.6.4"
    BRANCH="test/tester3-noshell-$(date +%m%d-%H%M)"
    TITLE="[TEST 3.6.4] enable_shell=false 验证"
    EXPECT="Actions 日志无 shell 调用记录"
    ;;
  3)
    TEST_ID="3.6.3+3.6.4"
    BRANCH="test/tester3-notools-$(date +%m%d-%H%M)"
    TITLE="[TEST 3.6.3+3.6.4] web_search + shell 同时关闭"
    EXPECT="Actions 日志无 web_search 和 shell 调用记录"
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

# 复用 web-search-trigger 代码
echo "==> 写入 quality-tests/tools-disabled-test.ts（工具关闭验证）"
cat > quality-tests/tools-disabled-test.ts << 'EOF'
import { experimental_useOptimistic } from 'react'
import { styleText } from 'node:util'

// 使用实验性/新 API — 正常情况下会触发 web_search
export function ExperimentalComponent() {
  const [optimistic, setOptimistic] = experimental_useOptimistic(null)
  return { optimistic }
}

// Node.js 22 API — 正常情况下会触发 web_search
export function colorOutput(msg: string) {
  console.log(styleText('green', msg))
}

// 依赖版本问题 — 正常情况下会触发 shell
import Fastify from 'fastify'
const app = Fastify()
app.decorateRequest('user', null)
EOF

git add quality-tests/tools-disabled-test.ts
git commit -m "test: add tools-disabled test (tester 3 — ${TEST_ID})"

git push -u origin "$BRANCH"

PR_URL=$(gh pr create \
  --title "$TITLE" \
  --base "$BASE_BRANCH" \
  --body "$(cat << BODY
## 目的

验证工具关闭配置 (${TEST_ID})。

## 当前配置

${TEST_ID} — 相关工具已关闭

## 代码改动

\`quality-tests/tools-disabled-test.ts\` — 含新/实验性 API + 依赖版本问题
正常情况下应触发 web_search / shell，但当前已关闭。

## 预期 Bot 行为

- ${EXPECT}

## 验证方式

1. PR → Checks → Code Review → 展开日志
2. 搜索 \`[web_search_debug]\` 和 \`[shell_debug]\` — 应无结果

## 测试完成后

⚠️ 恢复 workflow 配置!
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (${TEST_ID}): ${PR_URL}"
echo "================================================================"
echo ""
echo "验证方式: Actions 日志 → 搜索 web_search_debug / shell_debug"
echo "预期: ${EXPECT}"
echo ""
echo "⚠️  测试完成后恢复 workflow 配置!"
