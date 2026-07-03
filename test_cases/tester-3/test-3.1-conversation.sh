#!/usr/bin/env bash
#
# test-3.1-conversation.sh — 对话式追问交互测试
#
# 验证项目:
#   3.1.1 行级评论追问 — Bot 回复引用代码上下文
#   3.1.2 续轮追问 — 多轮上下文保持
#   3.1.3 不带 @bot 不触发
#   3.1.4 Bot 自回复不自触发（观察 Actions）
#   3.1.5 追问引用文件完整 diff
#   3.1.6 追问引用 PR 摘要
#
# 前置条件:
#   已运行 setup-3.3-noise-control.sh 且 Bot 已产出行级评论
#
# 注意:
#   对话追问需要在 GitHub PR 页面的行级评论 thread 中手动操作。
#   本脚本提供操作指南和验证清单。
#
# 用法:
#   bash test_cases/tester-3/test-3.1-conversation.sh
#
set -euo pipefail

BRANCH_FILE="/tmp/tester3-noise-branch"
if [[ -f "$BRANCH_FILE" ]]; then
  BRANCH="$(cat "$BRANCH_FILE")"
else
  echo "错误: 找不到分支记录文件 $BRANCH_FILE"
  echo "请先运行: bash test_cases/tester-3/setup-3.3-noise-control.sh"
  exit 1
fi

echo "================================================================"
echo "  场景: 3.1 对话式追问交互"
echo "  测试分支: ${BRANCH}"
echo "================================================================"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚠️  对话追问需要在 GitHub PR 页面手动操作"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "步骤 1 (3.1.1) — 行级评论追问:"
echo "  在 Bot 产出的 processPayment SQL 注入评论 thread 中输入:"
echo "  ---"
echo '  @codesentinel 为什么直接拼接 SQL 是个问题？可以具体说说攻击场景吗？'
echo "  ---"
echo "  预期: Bot 回帖引用对应代码行 + 具体 SQL 注入攻击解释"
echo ""
echo "步骤 2 (3.1.2) — 续轮追问:"
echo "  等 Bot 回复后，在同一 thread 继续输入:"
echo "  ---"
echo '  @codesentinel 用参数化查询的话，这段代码应该怎么改？'
echo "  ---"
echo "  预期: Bot 回复含修改建议，引用上一轮对话内容"
echo ""
echo "步骤 3 (3.1.3) — 不带 @bot 不触发:"
echo "  在同一 thread 中直接回复（不含 @codesentinel）:"
echo "  ---"
echo "  我理解了，谢谢"
echo "  ---"
echo "  预期: Bot 无任何响应"
echo ""
echo "步骤 4 (3.1.4) — Bot 自回复不自触发:"
echo "  观察步骤 1/2 中 Bot 回帖后:"
echo "  预期: Bot 回帖后无新的 workflow run（不自触发）"
echo "  验证: Actions 标签页无新的 'Code Review' run"
echo ""
echo "步骤 5 (3.1.5) — 追问引用文件完整 diff:"
echo "  在 Bot 评论 thread 中输入:"
echo "  ---"
echo '  @codesentinel 这个文件整体有什么架构问题吗？'
echo "  ---"
echo "  预期: 回复内容涵盖多行变更的上下文（不只单行）"
echo ""
echo "步骤 6 (3.1.6) — 追问引用 PR 摘要:"
echo "  在 Bot 评论 thread 中输入:"
echo "  ---"
echo '  @codesentinel 这个改动和 PR 目标有什么关系？'
echo "  ---"
echo "  预期: 回复引用 PR title/description 中的信息"
echo ""
echo "================================================================"
echo "  验证清单"
echo "================================================================"
echo ""
echo "  - [ ] 3.1.1: Bot 回复引用代码行 + SQL 注入解释"
echo "  - [ ] 3.1.2: Bot 回复含修改建议 + 关联上轮内容"
echo "  - [ ] 3.1.3: 普通回复（无 mention）Bot 无响应"
echo "  - [ ] 3.1.4: Bot 回帖后无新 workflow run"
echo "  - [ ] 3.1.5: 回复涵盖多行变更上下文"
echo "  - [ ] 3.1.6: 回复引用 PR title/description 信息"
echo ""
