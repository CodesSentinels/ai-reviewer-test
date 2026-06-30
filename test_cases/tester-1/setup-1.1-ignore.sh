#!/usr/bin/env bash
#
# setup-1.1-ignore.sh — 准备 1.1.6 ignore 跳过场景
#
# 验证项目:
#   1.1.6 PR body 包含 @codesentinel: ignore → Bot 不产出任何评论
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-1/setup-1.1-ignore.sh
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
BRANCH="test/tester1-ignore-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 1.1.6 @codesentinel: ignore 跳过"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

echo "==> 写入含问题代码（理论上应被审查但被 ignore 屏蔽）"
cat > utils/ignored-code.ts << 'EOF'
// utils/ignored-code.ts
// 这段代码有明显问题，但 PR 设置了 ignore，Bot 不应评论
export function badFunction(input: any) {
  const query = `DELETE FROM users WHERE id = '${input}'`
  eval(query)
  return query
}
EOF

git add utils/ignored-code.ts
git commit -m "test: add code with issues (should be ignored by bot)"

git push -u origin "$BRANCH"

PR_URL=$(gh pr create \
  --title "[TEST 1.1.6] ignore 关键词跳过审查验证" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
这个 PR 不需要 AI 审查。

@codesentinel: ignore

---

## 用途

验证用例 1.1.6：PR body 中含 `@codesentinel: ignore` 时，Bot 应完全不产出任何评论。

## 预期 Bot 行为

- **不产出**任何摘要评论
- **不产出**任何行级评论
- GitHub Actions 日志中应有 "ignore" 相关跳过记录

## 验证清单

- [ ] 1.1.6: Actions 运行完成后，PR 上无任何 Bot 评论
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (1.1.6): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 Actions 运行完成后检查 PR 是否无任何 Bot 评论。"
