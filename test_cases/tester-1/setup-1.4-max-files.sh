#!/usr/bin/env bash
#
# setup-1.4-max-files.sh — 准备 1.4.3 max_files 限制场景
#
# 验证项目:
#   1.4.3 max_files: 3 时，6 个文件的 PR 只审查前 3 个，摘要记录跳过统计
#
# 前置操作（手动）:
#   在 .github/workflows/ai-reviewer.yml 中临时设置:
#     max-files: '3'
#   测试完成后恢复原值。
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-1/setup-1.4-max-files.sh
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
BRANCH="test/tester1-maxfiles-$(date +%m%d-%H%M)"

# 检查 workflow 是否已配置 max-files: 3
WORKFLOW_FILE=".github/workflows/ai-reviewer.yml"
if grep -q "max-files:" "$WORKFLOW_FILE" 2>/dev/null; then
  CURRENT_MAX=$(grep "max-files:" "$WORKFLOW_FILE" | head -1 | grep -oE '[0-9]+' | head -1)
  if [[ "$CURRENT_MAX" != "3" ]]; then
    echo "⚠️  警告: workflow 中 max-files 当前值为 ${CURRENT_MAX}，不是 3"
    echo "   请先手动修改 ${WORKFLOW_FILE} 中的 max-files 为 '3'"
    echo "   然后重新运行本脚本"
    echo ""
    read -p "是否仍然继续？(y/N) " confirm
    [[ "$confirm" =~ ^[yY]$ ]] || exit 1
  fi
fi

echo "================================================================"
echo "  场景: 1.4.3 max_files 限制（6 个文件，限制为 3）"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"
git branch --unset-upstream

echo "==> 创建 6 个 TS 文件（每个含除零问题）"
mkdir -p utils
TS_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
for i in $(seq 1 6); do
  cat > "utils/max-files-module${i}.ts" << EOF
// utils/max-files-module${i}.ts
// generated: ${TS_TIME}
export function compute${i}(x: number): number {
  // 问题: 未检查 x=0 时的除零
  return 100 / x
}

export function transform${i}(data: string[]): string[] {
  // 问题: 未处理空数组
  return data.map(s => s.trim())
}
EOF
done

git add utils/max-files-module*.ts
git commit -m "test: add 6 modules for max_files limit test (1.4.3)

6 个文件均含除零问题，期望在 max_files=3 时只审查前 3 个"

git push origin "${BRANCH}:${BRANCH}"

PR_URL=$(gh pr create \
  --title "[TEST 1.4.3] max_files 限制验证（6 文件限制为 3）" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 `max_files` 配置限制（用例 1.4.3）。

> ⚠️ 需要在 `.github/workflows/ai-reviewer.yml` 中临时设置 `max-files: '3'`

## 变更内容

新增 6 个 TS 文件（`utils/max-files-module1.ts` ~ `utils/max-files-module6.ts`），每个都含除零问题。

## 预期 Bot 行为

- 只审查前 3 个文件
- 摘要评论中记录跳过统计（如 "skipped 3 files"）
- Actions 日志中可见文件截断记录

## 验证清单

- [ ] 1.4.3: 摘要中只涉及 3 个文件
- [ ] 1.4.3: 摘要中出现跳过文件数量的记录

## 测试后恢复

验证完成后请将 `max-files` 恢复为原始值（避免影响后续测试）。
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (1.4.3): ${PR_URL}"
echo "================================================================"
echo ""
echo "⚠️  测试完成后记得恢复 ${WORKFLOW_FILE} 中的 max-files 配置！"
