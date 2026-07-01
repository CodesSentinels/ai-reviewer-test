#!/usr/bin/env bash
#
# push-1.2-commit-b.sh — 推送增量审查的 Commit B
#
# 前置条件:
#   - 已运行 setup-1.2-incremental.sh 并等待 Bot 完成首次审查
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   bash test_cases/tester-1/push-1.2-commit-b.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# 读取 setup 阶段写入的分支名
BRANCH_FILE="/tmp/tester1-incremental-branch"
if [[ -f "$BRANCH_FILE" ]]; then
  BRANCH="$(cat "$BRANCH_FILE")"
else
  echo "错误: 找不到分支记录文件 $BRANCH_FILE"
  echo "请先运行: bash test_cases/tester-1/setup-1.2-incremental.sh"
  exit 1
fi

echo "================================================================"
echo "  场景: 1.2 增量审查 — 步骤 2/3: push Commit B"
echo "  分支: ${BRANCH}"
echo "================================================================"
echo ""

git checkout "$BRANCH"
git fetch origin "$BRANCH" --quiet

# ---- Commit B ----
echo "==> Commit B: 追加 divide + power（含已知问题）"
cat >> utils/math.ts << 'EOF'

export function divide(a: number, b: number): number {
  return a / b  // 问题: 未检查除零（b=0 时返回 Infinity）
}

export function power(base: number, exp: number): number {
  // 问题: 负指数处理不当（exp < 0 时循环不执行，返回 1）
  let result = 1
  for (let i = 0; i < exp; i++) {
    result *= base
  }
  return result
}
EOF

git add utils/math.ts
git commit -m "feat: add divide + power to math utils (Commit B - incremental review test)

已知问题（供增量审查验证）:
- divide: 未检查 b=0 的除零情况
- power: 负指数时循环不执行，结果错误"

git push origin "${BRANCH}:${BRANCH}"

echo ""
echo "================================================================"
echo "  ✅ Commit B 已 push"
echo "================================================================"
echo ""
echo "等待 Bot 完成增量审查（约 1 分钟）后验证:"
echo ""
echo "  ✓ 1.2.1: Bot 只评论 divide / power，不重复提及 add / multiply"
echo "  ✓ 1.2.2: 摘要评论 HTML 中 commit_ids_reviewed 区块包含 Commit B 的 SHA"
echo ""
echo "完成后可在 PR 评论区发: @codesentinel full review  （验证 1.2.3）"
