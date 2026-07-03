#!/usr/bin/env bash
#
# test-3.2-turn-limit.sh — 对话轮次与截断测试
#
# 验证项目:
#   3.2.1 连续追问达 10 轮 → 第 11 轮被拒
#   3.2.2 长对话上下文截断 → Bot 仍正常回复
#   3.2.3 截断后保留最近内容 → 引用最近几轮
#   3.2.4 issue_comment 对话不支持 → Bot 不回复
#
# 前置条件:
#   已运行 setup-3.3-noise-control.sh 且 Bot 已产出行级评论
#
# 注意:
#   3.2.1 需要在同一 thread 连续追问 11 次，操作耗时较长。
#   3.2.4 需要在 PR 主评论区（非行级 thread）发送命令。
#
# 用法:
#   bash test_cases/tester-3/test-3.2-turn-limit.sh
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
echo "  场景: 3.2 对话轮次与截断"
echo "  测试分支: ${BRANCH}"
echo "================================================================"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  关键常量:"
echo "  MAX_CONVERSATION_TURNS = 10（单 thread 最多 10 轮 Bot 回复）"
echo "  MAX_CHAIN_CHARS = 12,000（对话链超 12k 字符时截断）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "测试 3.2.1 — 10 轮限制（在 Bot 行级评论 thread 中操作）:"
echo ""
echo "  在同一个 thread 中连续追问 11 次:"
echo "  第 1 轮: @codesentinel 这段代码有什么问题？"
echo "  第 2 轮: @codesentinel 能详细解释吗？"
echo "  第 3 轮: @codesentinel 有什么替代方案？"
echo "  第 4 轮: @codesentinel 性能影响如何？"
echo "  第 5 轮: @codesentinel 安全方面呢？"
echo "  第 6 轮: @codesentinel 最佳实践是什么？"
echo "  第 7 轮: @codesentinel 有没有参考链接？"
echo "  第 8 轮: @codesentinel 这种模式常见吗？"
echo "  第 9 轮: @codesentinel 还有其他考虑吗？"
echo "  第 10 轮: @codesentinel 总结一下？"
echo "  第 11 轮: @codesentinel 还有问题想问"
echo ""
echo "  预期: 第 1~10 轮正常回复，第 11 轮收到 \"轮次已达上限\" 提示"
echo ""
echo "----------------------------------------------------------------"
echo ""
echo "测试 3.2.2 — 长对话上下文截断:"
echo ""
echo "  在 thread 中每轮发 500+ 字长文追问:"
echo "  ---"
echo '  @codesentinel 我有一个很长的问题需要详细讨论...'
echo '  [此处粘贴 500+ 字的技术讨论内容]'
echo "  ---"
echo "  预期: Bot 不报 token 超限错误，正常回复"
echo ""
echo "----------------------------------------------------------------"
echo ""
echo "测试 3.2.3 — 截断后保留最近内容:"
echo ""
echo "  在第 8 轮追问时引用第 7 轮的内容:"
echo "  ---"
echo '  @codesentinel 你刚才提到的那个方案，能再详细说说吗？'
echo "  ---"
echo "  预期: Bot 回复关联最近对话内容（第 7 轮），而非第 1 轮"
echo ""
echo "----------------------------------------------------------------"
echo ""
echo "测试 3.2.4 — issue_comment 对话不支持:"
echo ""
echo "  在 PR 主评论区（Conversation 标签页底部输入框）输入:"
echo "  ---"
echo '  @codesentinel 解释一下这个 PR'
echo "  ---"
echo "  预期: Bot 不回复（仅 pull_request_review_comment 支持对话）"
echo ""
echo "================================================================"
echo "  验证清单"
echo "================================================================"
echo ""
echo "  - [ ] 3.2.1: 第 11 轮收到轮次上限提示"
echo "  - [ ] 3.2.2: 长文追问 Bot 正常回复（无 token 超限）"
echo "  - [ ] 3.2.3: Bot 引用最近轮次内容"
echo "  - [ ] 3.2.4: 主评论区追问 Bot 无响应"
echo ""
