#!/usr/bin/env bash
#
# apply-changes.sh — 应用迭代二 · 成员 D 测试用代码改动（仅生成代码，不创建 PR）
#
# 用法:
#   cd ai-reviewer-test
#   bash test_cases/iteration2-member-d/code-changes/apply-changes.sh
#
# 做什么:
#   仅把 utils/share-link.ts 写入工作区（含多个安全/正确性问题 + 同类问题）。
#   分支创建 / 提交 / 推送 / 建 PR 由你手动完成。
#
# 目的:
#   - 让 ai-reviewer 产出多条行级审查评论，作为"多轮追问对话"的锚点
#   - 制造同类问题（弱随机数 x2），便于观察噪音控制的合并/折叠

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$REPO_ROOT"
echo "工作目录: $(pwd)"

# 写入被审查文件
echo "==> 生成 utils/share-link.ts"
cp "$SCRIPT_DIR/share-link.ts" utils/share-link.ts

echo ""
echo "============================================="
echo "  代码已生成: utils/share-link.ts"
echo "============================================="
echo ""
echo "下一步（由你手动完成）:"
echo "  1. 创建分支并提交:"
echo "       git checkout -b test/iter2-member-d"
echo "       git add utils/share-link.ts"
echo "       git commit -m 'test: iter2 member-d share-link utils'"
echo "       git push -u origin test/iter2-member-d"
echo "  2. 创建 PR（网页或 gh pr create）"
echo "  3. 等待自动 review 产出行级评论后，运行多轮对话脚本:"
echo "       PR=<PR编号> bash docs/run-iter2-member-d-test.sh"
