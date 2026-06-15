#!/usr/bin/env bash
#
# apply-changes.sh — 一键应用迭代二 · 成员 D 测试用代码改动并创建 PR
#
# 用法:
#   cd ai-reviewer-test
#   bash test_cases/iteration2-member-d/code-changes/apply-changes.sh
#
# 做什么:
#   1. 创建测试分支 test/iter2-member-d
#   2. 新建 utils/share-link.ts（含多个安全/正确性问题 + 同类问题）
#   3. 提交、推送并创建 PR
#
# 目的:
#   - 让 ai-reviewer 产出多条行级审查评论，作为"多轮追问对话"的锚点
#   - 制造同类问题（弱随机数 x2），便于观察噪音控制的合并/折叠
#
# 前置条件:
#   - gh CLI 已登录，且当前仓库已配置 ai-reviewer workflow
#   - 使用的 Action 分支需包含成员 D 的代码（conversation.ts / command-handler 接线）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$REPO_ROOT"
echo "工作目录: $(pwd)"

# 1. 创建分支
BRANCH="test/iter2-member-d"
echo "==> 创建分支 ${BRANCH}"
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# 2. 新建被审查文件
echo "==> 创建 utils/share-link.ts"
cp "$SCRIPT_DIR/share-link.ts" utils/share-link.ts

# 3. 提交
echo "==> 提交代码"
git add utils/share-link.ts
git commit -m "test: iter2 member-d — share-link utils for conversation & noise-control review

改动内容:
- utils/share-link.ts: 分享链接工具，故意引入
  * [安全] 硬编码密钥
  * [安全] 弱随机数 x2（同类问题，验证去重/折叠）
  * [安全] ReDoS 风险正则
  * [正确性] JSON.parse 未处理异常
  * [正确性] 分页 off-by-one
  * [正确性] 未 await 的异步副作用"

# 4. 推送 + 创建 PR
echo "==> 推送到远程"
git push -u origin "$BRANCH"

echo "==> 创建 PR"
PR_URL=$(gh pr create \
  --title "[TEST] 迭代二 · 成员 D 对话交互与噪音控制端到端验证" \
  --body "$(cat << 'EOF'
## 目的

验证 ai-reviewer 迭代二 · 成员 D 功能：
- §2.3 对话式追问交互（多轮 @ai-reviewer 追问）
- §2.5 评论噪音控制（同类合并 / 折叠 / 汇总评论）

## 代码改动

`utils/share-link.ts` — 故意包含多个可审查问题：

| 类别 | 问题 |
| :--- | :--- |
| 安全 | 硬编码密钥 `SIGNING_SECRET` |
| 安全 | 弱随机数 `generateShareToken` / `generateShortId`（同类 x2） |
| 安全 | `isValidShareUrl` ReDoS 风险正则 |
| 正确性 | `parseSharePayload` 未处理 JSON.parse 异常 |
| 正确性 | `paginate` off-by-one |
| 正确性 | `trackShare` 未 await 异步副作用 |

## 测试方法

1. 等待自动 review 完成（产出行级评论）
2. 运行多轮对话脚本：
   \`\`\`
   PR=<PR编号> bash docs/run-iter2-member-d-test.sh
   \`\`\`
3. 按 \`docs/08-iteration2-member-d-test-case.md\` 核对预期
EOF
)")

PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$')
echo ""
echo "============================================="
echo "  PR 已创建: ${PR_URL}"
echo "  PR 编号:   #${PR_NUM}"
echo "============================================="
echo ""
echo "下一步:"
echo "  1. 等待自动 review 完成（约 1~3 分钟），确认 Bot 产出了行级评论"
echo "  2. 运行多轮对话测试:"
echo "     PR=${PR_NUM} bash docs/run-iter2-member-d-test.sh"
echo "  3. 或 DRY RUN 预览（不实际发送）:"
echo "     DRY=1 PR=${PR_NUM} bash docs/run-iter2-member-d-test.sh"
