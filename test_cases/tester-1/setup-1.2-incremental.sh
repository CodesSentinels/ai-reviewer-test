#!/usr/bin/env bash
#
# setup-1.2-incremental.sh — 准备 1.2 增量审查场景
#
# 验证项目:
#   1.2.1 push 新 commit 后仅审查新增变更
#   1.2.2 摘要评论中记录已审查 commit SHA
#   1.2.3 @codesentinel full review 全量审查
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-1/setup-1.2-incremental.sh
#
# 流程:
#   步骤 1 — 运行本脚本（push Commit A，创建 PR）
#   步骤 2 — 等待 Bot 完成首次审查（1~3 分钟）
#   步骤 3 — 运行: bash test_cases/tester-1/push-1.2-commit-b.sh
#   步骤 4 — 等待 Bot 增量审查完成
#   步骤 5 — 在 PR 评论区发: @codesentinel full review
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  SECRETS_FILE="$REPO_ROOT/.secrets"
  if [[ -f "$SECRETS_FILE" ]]; then
    export GITHUB_TOKEN="$(grep '^GITHUB_TOKEN=' "$SECRETS_FILE" | sed 's/^GITHUB_TOKEN=//' | tr -d '[:space:]')"
  fi
fi
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "❌ GITHUB_TOKEN 未设置，请在 .secrets 文件中配置或通过环境变量传入" >&2
  exit 1
fi
export GH_TOKEN="$GITHUB_TOKEN"

BASE_BRANCH="test/dev4"
BRANCH="test/tester1-incremental-$(date +%m%d-%H%M)"

# 记录分支名供 commit-b 脚本复用
echo "$BRANCH" > /tmp/tester1-incremental-branch

echo "================================================================"
echo "  场景: 1.2 增量审查 — 步骤 1/3: 创建 PR（Commit A）"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"
git branch --unset-upstream

# ---- Commit A ----
echo "==> Commit A: 新增 utils/math.ts（基础运算）"
printf '// utils/math.ts\n// generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" > utils/math.ts
cat >> utils/math.ts << 'TSEOF'
export function add(a: number, b: number): number {
  return a + b
}

export function multiply(a: number, b: number): number {
  return a * b
}
TSEOF

git add utils/math.ts
git commit -m "feat: add math utils - add + multiply (Commit A)"

git push origin "${BRANCH}:${BRANCH}"

# 保存分支名供 push-1.2-commit-b.sh 使用
echo "$BRANCH" > /tmp/tester1-incremental-branch

PR_URL=$(gh pr create \
  --title "[TEST 1.2] 增量审查验证" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 AI Reviewer 增量审查流程（用例 1.2.1 ~ 1.2.3）。

## 当前内容（Commit A）

- `utils/math.ts`（新增）：`add` + `multiply`，代码简单无明显问题

## 后续步骤

Commit A 审查完成后，将追加 Commit B（含 divide/power 的问题代码），验证 Bot 仅对新变更评论。

## 验证清单

### Commit A 审查后
- [ ] 1.2.2: 摘要评论 HTML 源码中含 `commit_ids_reviewed` 区块，包含 Commit A 的 SHA

### Commit B push 后
- [ ] 1.2.1: Bot 第二次评论**只涉及** `divide` / `power`，不重复提及 `add` / `multiply`
- [ ] 1.2.2: commit_ids_reviewed 区块追加了 Commit B 的 SHA

### full review 后
- [ ] 1.2.3: Bot 重新审查从 base 到 HEAD 的全部变更
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (Commit A): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 Bot 完成首次审查（1~3 分钟）后，运行下一步:"
echo ""
echo "  bash test_cases/tester-1/push-1.2-commit-b.sh"
echo ""
echo "验证 1.2.2: 查看摘要评论的 HTML 源码，确认含 commit_ids_reviewed 区块"
