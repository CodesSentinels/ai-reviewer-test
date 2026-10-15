#!/usr/bin/env bash
# R6：把 ai-reviewer 的锁定 SHA 换成 #325 修复后的新 SHA（dist 已重新打包，对应 a6028a02）。
#
# 用法（在仓库根目录执行）：
#   bash functional-tests/ai-reviewer-fixtures/r6-pin.sh
#
# 做的事（全部用 git worktree 在 /tmp 里完成，不切换你当前的分支，不改工作区）：
#   1. main：建分支 test/r6-pin-main，替换 workflow 里的 ref，提交、推送、建 PR 并合并（评论类事件用 main 的 workflow）；
#   2. 三个测试分支（-20261008 / -b / -c）：直接替换 workflow 里的 ref，提交并推送（pull_request 事件用 PR 分支自己的 workflow）。
# 只改 .github/workflows/ai-reviewer.yml 里 ai-reviewer 那一处 checkout 的 ref，不读取、不打印任何 Secret。
# 兼容 macOS bash 3.2。
set -euo pipefail

REPO="CodesSentinels/ai-reviewer-test"
OLD_SHA="${OLD_SHA:-24c87694013c9e5655a920404e582123cbde09fd}"
NEW_SHA="${NEW_SHA:-acc61bb5765e26285f27b5e45c68a08878dd7667}"
ORIG="$(git rev-parse --show-toplevel)"
WT="${WT:-/tmp/ft-r6-pin-wt}"
LOG="${LOG:-/tmp/ft-r6-pin.log}"
BRANCHES="test/ai-reviewer-develop-functional-20261008 test/ai-reviewer-develop-functional-20261008-b test/ai-reviewer-develop-functional-20261008-c"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

edit_pin() {
  # 不依赖旧 SHA 是哪一个：直接把 ai-reviewer 那处 checkout 的 ref 换成新 SHA
  python3 - "${NEW_SHA}" <<'PY2'
import re, sys
new = sys.argv[1]
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
if new in s:
    print('already pinned to new SHA')
    sys.exit(0)
out, n = re.subn(r'(repository: CodesSentinels/ai-reviewer\n\s+ref: )[0-9a-f]{40}', lambda m: m.group(1) + new, s, count=1)
assert n == 1, 'ai-reviewer checkout ref not found'
out = re.sub(r'# R\d 锁定 SHA（[^）]*）', '# R6 锁定 SHA（#325 修复分支 fix/similar-comments-r5，dist 对应 a6028a021037372639d96c7c3021fb9931379eeb）', out)
open(p, 'w', encoding='utf-8').write(out)
PY2
}

fresh_worktree() {   # $1 = 本地分支名  $2 = 起点（origin/xxx）
  rm -rf "${WT}"
  git -C "${ORIG}" worktree prune
  git -C "${ORIG}" worktree add -q -B "$1" "${WT}" "$2"
  cd "${WT}"
}

# 测试分支可能已在别的 worktree / 当前工作区被检出（git 不允许同一分支同时检出两处），
# 所以用分离 HEAD 的临时 worktree，提交后 push 到同名远端分支。
detached_worktree() {   # $1 = 起点（origin/xxx）
  rm -rf "${WT}"
  git -C "${ORIG}" worktree prune
  git -C "${ORIG}" worktree add -q --detach "${WT}" "$1"
  cd "${WT}"
}

: > "${LOG}"
git -C "${ORIG}" fetch -q origin
say "旧 SHA: ${OLD_SHA}"
say "新 SHA: ${NEW_SHA}"

# 1) main（走 PR 并合并；已经是新 SHA 则跳过）
if git -C "${ORIG}" show "origin/main:.github/workflows/ai-reviewer.yml" | grep -q "${NEW_SHA}"; then
  say "main 已是新 SHA，跳过"
else
  fresh_worktree "test/r6-pin-main" "origin/main"
  edit_pin
  git diff --stat
  git add -A
  git commit -q -m "test: R6 锁定 SHA 换成 #325 修复后的 ${NEW_SHA:0:8}"
  git push -q -u origin "test/r6-pin-main"
  url="$(gh pr create --repo "${REPO}" --base main --head "test/r6-pin-main" --title "test: R6 锁定 SHA 换成 #325 修复后的 ${NEW_SHA:0:8}" --body "R6：评论类事件使用 main 的 workflow，需要先把锁定 SHA 换成修复后的提交。关联总回归 Issue #299。")"
  n="$(printf '%s' "${url}" | grep -oE '[0-9]+$')"
  say "已创建 PR #${n}: ${url}"
  if gh pr merge "${n}" --repo "${REPO}" --squash --delete-branch; then
    say "已合并 PR #${n}"
  else
    say "自动合并失败，请在 GitHub 上手动合并 PR #${n} 后重新执行本脚本（已处理过的分支会被跳过）。"
    exit 1
  fi
fi

# 2) 三个测试分支（直接提交推送）
for b in ${BRANCHES}; do
  say "== ${b}"
  detached_worktree "origin/${b}"
  if grep -q "${NEW_SHA}" .github/workflows/ai-reviewer.yml; then
    say "已是新 SHA，跳过"
    continue
  fi
  edit_pin
  git add -A
  git commit -q -m "test: R6 锁定 SHA 换成 #325 修复后的 ${NEW_SHA:0:8}"
  git push -q origin "HEAD:${b}"
  say "已推送 ${b}"
done

git -C "${ORIG}" worktree remove --force "${WT}" 2>/dev/null || true
say "完成。检查：git -C '${ORIG}' fetch origin && git -C '${ORIG}' show origin/main:.github/workflows/ai-reviewer.yml | grep -n 'ref:'"
