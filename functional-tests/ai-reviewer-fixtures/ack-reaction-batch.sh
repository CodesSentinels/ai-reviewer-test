#!/usr/bin/env bash
# FT-117：关闭命令 ack reaction。评论类事件使用 main 上的 workflow，所以需要临时修改 main。
#
# 三个子命令，按顺序执行（每个都是独立的，可单独重跑）：
#   bash functional-tests/ai-reviewer-fixtures/ack-reaction-batch.sh apply    # 在 main 上加 command_ack_reaction: "off"（建 PR 并合并）
#   bash functional-tests/ai-reviewer-fixtures/ack-reaction-batch.sh probe    # 在卫星 PR #304 发一条 help，等待后打印评论上的 reaction
#   bash functional-tests/ai-reviewer-fixtures/ack-reaction-batch.sh revert   # 还原 main 上的设置（建 PR 并合并）
#
# 使用 git worktree 在 /tmp 里工作，不切换你当前的分支，不改动当前工作区。
# 会执行：git commit / git push / gh pr create / gh pr merge（你本人的账号）。不会读取或打印任何 Secret。
# 兼容 macOS bash 3.2。
set -euo pipefail

REPO="CodesSentinels/ai-reviewer-test"
ORIG="$(git rev-parse --show-toplevel)"
WT="${WT:-/tmp/ft-ack-wt}"
LOG="${LOG:-/tmp/ft-ack-reaction.log}"
TARGET_PR="${TARGET_PR:-304}"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$LOG"; }

new_worktree() {   # $1 = 分支名
  rm -rf "$WT" 2>/dev/null || true
  git -C "$ORIG" worktree prune
  git -C "$ORIG" fetch -q origin main
  git -C "$ORIG" worktree add -q -B "$1" "$WT" origin/main
  cd "$WT"
}

edit_workflow() {   # $1 = add | remove
  python3 - "$1" <<'PY'
import re, sys
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
line = '          command_ack_reaction: "off"\n'
if sys.argv[1] == 'add':
    if 'command_ack_reaction' in s:
        s = re.sub(r"^ +command_ack_reaction: .*\n", lambda m: line, s, flags=re.M)
    else:
        s = s.replace("          enable_semgrep: true\n", "          enable_semgrep: true\n" + line, 1)
else:
    s = re.sub(r"^ +command_ack_reaction: .*\n", "", s, flags=re.M)
open(p, 'w', encoding='utf-8').write(s)
PY
}

pr_and_merge() {   # $1 = 分支名  $2 = 标题  $3 = 正文
  git push -q -u origin "$1"
  local url n
  url="$(gh pr create --repo "$REPO" --base main --head "$1" --title "$2" --body "$3")"
  n="$(printf '%s' "$url" | grep -oE '[0-9]+$')"
  say "已创建 PR #$n: $url"
  if gh pr merge "$n" --repo "$REPO" --squash --delete-branch; then
    say "已合并 PR #$n"
  else
    say "自动合并失败（可能有分支保护/需要审批）。请在 GitHub 上手动合并 PR #$n 后再继续下一步。"
    exit 1
  fi
}

case "${1:-}" in
  apply)
    : > "$LOG"
    new_worktree "test/ack-reaction-off"
    edit_workflow add
    git diff --stat
    git add -A
    git commit -q -m "test: 临时关闭命令 ack reaction（FT-117，验证后还原）"
    pr_and_merge "test/ack-reaction-off" "test: 临时关闭命令 ack reaction（FT-117，验证后还原）" "临时测试，验证 command_ack_reaction 关闭后命令评论上没有 reaction；验证完成后会还原。关联总回归 Issue #299。"
    say "完成。下一步：bash functional-tests/ai-reviewer-fixtures/ack-reaction-batch.sh probe"
    ;;
  probe)
    printf '%s' '@ai-reviewer help' > /tmp/ft-ack-cmd.txt
    url="$(gh pr comment "$TARGET_PR" --repo "$REPO" --body-file /tmp/ft-ack-cmd.txt)"
    rm -f /tmp/ft-ack-cmd.txt
    say "已发布命令评论: $url"
    cid="$(printf '%s' "$url" | grep -oE '[0-9]+$')"
    say "等待 90 秒让 workflow 处理…"
    sleep 90
    say "评论 $cid 上的 reaction（空表示没有）："
    gh api "repos/$REPO/issues/comments/$cid/reactions" --jq '.[]|"  \(.user.login) \(.content)"' | tee -a "$LOG"
    say "bot 回复："
    gh api "repos/$REPO/issues/$TARGET_PR/comments" --paginate --jq ".[]|select(.body|contains(\"cmd-reply:$cid:\"))|\"  \\(.created_at) 已回复\"" | tee -a "$LOG"
    say "完成。把评论链接发给 Claude，然后执行：bash functional-tests/ai-reviewer-fixtures/ack-reaction-batch.sh revert"
    ;;
  revert)
    new_worktree "test/ack-reaction-restore"
    edit_workflow remove
    git diff --stat
    git add -A
    git commit -q -m "test: 还原命令 ack reaction 设置（FT-117 验证完成）"
    pr_and_merge "test/ack-reaction-restore" "test: 还原命令 ack reaction 设置（FT-117 验证完成）" "还原临时测试改动：main 上的 workflow 恢复为默认的 ack reaction。关联总回归 Issue #299。"
    git -C "$ORIG" worktree remove --force "$WT" 2>/dev/null || true
    say "已还原。可检查：git -C '$ORIG' fetch origin main && git -C '$ORIG' diff 67a9144 origin/main -- .github/workflows/ai-reviewer.yml（应无差异）"
    ;;
  *)
    echo "用法: bash $0 apply|probe|revert" >&2
    exit 2
    ;;
esac
