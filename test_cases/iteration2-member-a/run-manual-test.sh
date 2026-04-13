#!/usr/bin/env bash
#
# run-manual-test.sh — 迭代二 · 成员 A 半自动集成测试脚本
#
# 功能:
#   用 gh CLI 依次贴出 README.md 中的命令评论。每条评论之后休眠 SLEEP_BETWEEN 秒，
#   等待 Actions 冷启动 + Bot 响应，最后打印完整 PR 评论列表供人工核对。
#
# 用法:
#   PR_NUMBER=123 ./run-manual-test.sh
#   PR_NUMBER=123 SLEEP_BETWEEN=45 ./run-manual-test.sh
#   PR_NUMBER=123 DRY_RUN=1 ./run-manual-test.sh     # 仅打印将要执行的动作
#
# 先决条件:
#   - gh CLI 已登录且对目标仓库有 write 权限
#   - 当前工作目录位于 ai-reviewer-test 仓库内
#
# 注意:
#   - 脚本会逐条发评论，不适合在生产 PR 上运行
#   - 某些用例（权限不足 / PR 作者豁免）需要多账号，本脚本仅覆盖单账号能完成的路径
#

set -euo pipefail

: "${PR_NUMBER:?PR_NUMBER env var is required}"
SLEEP_BETWEEN="${SLEEP_BETWEEN:-40}"
DRY_RUN="${DRY_RUN:-0}"

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "== Repo:       ${REPO}"
echo "== PR:         #${PR_NUMBER}"
echo "== Sleep:      ${SLEEP_BETWEEN}s between comments"
echo "== Dry run:    ${DRY_RUN}"
echo

# 用例: "<label>|<command-body>"
CASES=(
  "T01 help|@ai-reviewer help"
  "T02 codesentinel alias|@codesentinel help"
  "T03 case-insensitive|@AI-Reviewer HELP"
  "T04 full review|@ai-reviewer full review"
  "T05 kv args|@ai-reviewer review files=src/foo.ts"
  "T06 shell injection dollar|@ai-reviewer review \$(whoami)"
  "T07 shell injection backtick|@ai-reviewer review \`ls\`"
  "T08 cjk args|@ai-reviewer review 请审"
  "T14 ack resolve|@ai-reviewer resolve"
  "T18 conversation fallback|@ai-reviewer 这里为何用 forEach 而不是 map？"
  "T19 ignored (no bot mention)|just a plain comment with no mention"
)

post_comment() {
  local label="$1"
  local body="$2"
  echo "--> [${label}] ${body}"
  if [[ "$DRY_RUN" == "1" ]]; then
    return
  fi
  gh pr comment "$PR_NUMBER" --body "$body" >/dev/null
}

for entry in "${CASES[@]}"; do
  label="${entry%%|*}"
  body="${entry#*|}"
  post_comment "$label" "$body"
  echo "    sleeping ${SLEEP_BETWEEN}s ..."
  if [[ "$DRY_RUN" != "1" ]]; then
    sleep "$SLEEP_BETWEEN"
  fi
done

# 命令行超长的 T09 单独构造，避免 shell 环境变量展开
LONG_ARG=$(printf 'a%.0s' {1..520})
post_comment "T09 超长命令行" "@ai-reviewer review ${LONG_ARG}"
sleep "$SLEEP_BETWEEN"

# T10 参数个数超限
post_comment "T10 参数超限" "@ai-reviewer review a b c d e f g h i j k l m n o p q"
sleep "$SLEEP_BETWEEN"

echo
echo "== 评论列表 (PR #${PR_NUMBER}):"
if [[ "$DRY_RUN" != "1" ]]; then
  gh pr view "$PR_NUMBER" --json comments \
    --jq '.comments[] | {author: .author.login, createdAt, body: (.body|tostring|.[0:120])}'
fi

cat <<'EOF'

== 核对提示
  1. 对照 COMMANDS.md 中每一行期望，标记通过/失败
  2. T11 / T12 / T13 (权限相关) 需要多账号环境，本脚本未自动化
  3. T15 (幂等) 需要手动 re-run workflow，本脚本未自动化
  4. T17 (review_comment 事件) 需要在 Files changed tab 手动添加行内评论
  5. T20 (bot 自评论循环) 通过观察 Actions 日志验证

EOF
