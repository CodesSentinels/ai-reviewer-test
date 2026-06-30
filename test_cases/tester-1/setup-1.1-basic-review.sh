#!/usr/bin/env bash
#
# setup-1.1-basic-review.sh — 准备 1.1 基础 PR 审查场景
#
# 验证项目:
#   1.1.1 新建 PR 触发自动审查
#   1.1.2 PR 摘要评论格式（Walkthrough + Changes 表格）
#   1.1.3 行级评论定位准确
#   1.1.4 发布说明写入 PR 描述
#   1.1.6 @codesentinel: ignore 完全跳过
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-1/setup-1.1-basic-review.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# 读取 .secrets 中的 GITHUB_TOKEN（如未从环境传入）
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  SECRETS_FILE="$REPO_ROOT/.secrets"
  if [[ -f "$SECRETS_FILE" ]]; then
    export GITHUB_TOKEN="$(grep '^GITHUB_TOKEN=' "$SECRETS_FILE" | cut -d= -f2)"
  fi
fi
export GH_TOKEN="$GITHUB_TOKEN"

BASE_BRANCH="test/dev4"
BRANCH="test/tester1-basic-review-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 1.1 基础 PR 审查"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""

# 确保从 base 拉出新分支
git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

# ---- 1.1.1 / 1.1.2 / 1.1.3 / 1.1.4: 含安全问题的代码 ----
echo "==> 写入含已知问题的文件 utils/insecure-api.ts"
cat > utils/insecure-api.ts << 'EOF'
// utils/insecure-api.ts
import { createServer } from 'http'

/**
 * 请求处理函数
 * 包含多种典型问题供 AI 审查检测
 */
export function handleRequest(req: any, res: any) {
  // 安全问题 1: SQL 注入
  const userId = req.query.id
  const query = `SELECT * FROM users WHERE id = '${userId}'`

  // 安全问题 2: 未验证的 eval
  const code = req.body.expression
  const result = eval(code)

  // 正确性问题: 忘记 await（async 函数但调用方无法感知错误）
  async function saveData(data: any) {
    fetch('/api/save', { method: 'POST', body: JSON.stringify(data) })
  }

  // 性能问题: 循环内重复创建正则
  function filterItems(items: string[], pattern: string) {
    return items.filter(item => {
      const regex = new RegExp(pattern)
      return regex.test(item)
    })
  }

  saveData({ query, result })
  res.end(JSON.stringify({ result }))
}
EOF

git add utils/insecure-api.ts
git commit -m "feat: add insecure-api utils (1.1 基础审查测试)

包含:
- SQL 注入（直接拼接用户输入）
- 未验证的 eval 调用
- 异步函数缺少 await
- 循环内重复创建正则表达式"

# 推送
git push -u origin "$BRANCH"

# 创建 PR 1.1.1 — 正常触发审查
PR_URL=$(gh pr create \
  --title "[TEST 1.1] 基础 PR 审查：安全问题检测验证" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 AI Reviewer 基础审查流程（用例 1.1.1 ~ 1.1.4）。

## 代码改动

- `utils/insecure-api.ts`（新增）：包含 SQL 注入 / eval / 未 await / 循环创建正则

## 预期 Bot 行为

1. **1.1.1** — 1~3 分钟内自动产出评论
2. **1.1.2** — 顶部摘要评论含 `Walkthrough`、文件变更表格、`Summary by CodeSentinel`
3. **1.1.3** — 行级评论定位到对应问题代码行（±2 行内）
4. **1.1.4** — PR 描述底部出现 `Summary by CodeSentinel` release notes 段落

## 验证清单

- [ ] 1.1.1: Bot 产出评论
- [ ] 1.1.2: 摘要格式正确
- [ ] 1.1.3: 行级评论行号准确
- [ ] 1.1.4: PR 描述末尾有 release notes
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (1.1.1 ~ 1.1.4): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 1~3 分钟后验证以上四项。"
echo ""
echo "----------------------------------------------------------------"
echo "  下一步: 验证 1.1.6（ignore 跳过）"
echo "  运行: bash test_cases/tester-1/setup-1.1-ignore.sh"
echo "----------------------------------------------------------------"
