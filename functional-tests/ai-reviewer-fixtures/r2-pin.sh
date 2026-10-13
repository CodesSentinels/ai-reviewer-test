#!/usr/bin/env bash
# R2：把 ai-reviewer 的锁定 SHA 换成修复后的新 SHA（dist 已重新打包）。
#
# 用法（在仓库根目录执行）：
#   bash functional-tests/ai-reviewer-fixtures/r2-pin.sh
#
# 做的事（全部用 git worktree 在 /tmp 里完成，不切换你当前的分支，不改工作区）：
#   1. main：建分支 test/r2-pin-main，替换 workflow 里的 ref，提交、推送、建 PR 并合并（评论类事件用 main 的 workflow）；
#   2. 三个测试分支（-20261008 / -b / -c）：直接替换 workflow 里的 ref，提交并推送（pull_request 事件用 PR 分支自己的 workflow）。
# 只改 .github/workflows/ai-reviewer.yml 里 ai-reviewer 那一处 checkout 的 ref，不读取、不打印任何 Secret。
# 兼容 macOS bash 3.2。
set -euo pipefail

REPO="CodesSentinels/ai-reviewer-test"
OLD_SHA="${OLD_SHA:-8c84f45fab547821ecefbf56aabbf215eb9d7dbf}"
NEW_SHA="${NEW_SHA:-c96cd53e0c1a23abf85ecb21c5a0e90a255333c5}"
ORIG="$(git rev-parse --show-toplevel)"
WT="${WT:-/tmp/ft-r2-pin-wt}"
LOG="${LOG:-/tmp/ft-r2-pin.log}"
BRANCHES="test/ai-reviewer-develop-functional-20261008 test/ai-reviewer-develop-functional-20261008-b test/ai-reviewer-develop-functional-20261008-c"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

edit_pin() {
  python3 - "${OLD_SHA}" "${NEW_SHA}" <<'PY'
import sys
old, new = sys.argv[1], sys.argv[2]
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
if old not in s and new in s:
    print('already pinned to new SHA')
    sys.exit(0)
assert old in s, 'old SHA not found in workflow'
s = s.replace(old, new)
s = s.replace('# 本轮锁定 SHA，来源 develop，获取时间 2026-10-08T06:44:44Z', '# R2 锁定 SHA（修复分支 fix/regression-defects-r1，dist 对应 1ca3e94309ae54966a961052fa517848298a7cb5）')
open(p, 'w', encoding='utf-8').write(s)
PY
}

fresh_worktree() {   # $1 = 本地分支名  $2 = 起点（origin/xxx）
  rm -rf "${WT}"
  git -C "${ORIG}" worktree prune
  git -C "${ORIG}" worktree add -q -B "$1" "${WT}" "$2"
  cd "${WT}"
}

: > "${LOG}"
git -C "${ORIG}" fetch -q origin
say "旧 SHA: ${OLD_SHA}"
say "新 SHA: ${NEW_SHA}"

# 1) main（走 PR 并合并）
fresh_worktree "test/r2-pin-main" "origin/main"
edit_pin
git diff --stat
git add -A
git commit -q -m "test: R2 锁定 SHA 换成修复后的 ${NEW_SHA:0:8}"
git push -q -u origin "test/r2-pin-main"
url="$(gh pr create --repo "${REPO}" --base main --head "test/r2-pin-main" --title "test: R2 锁定 SHA 换成修复后的 ${NEW_SHA:0:8}" --body "R2：评论类事件使用 main 的 workflow，需要先把锁定 SHA 换成修复后的提交。关联总回归 Issue #299。")"
n="$(printf '%s' "${url}" | grep -oE '[0-9]+$')"
say "已创建 PR #${n}: ${url}"
if gh pr merge "${n}" --repo "${REPO}" --squash --delete-branch; then
  say "已合并 PR #${n}"
else
  say "自动合并失败，请在 GitHub 上手动合并 PR #${n} 后重新执行本脚本（已处理过的分支会被跳过）。"
  exit 1
fi

# 2) 三个测试分支（直接提交推送）
for b in ${BRANCHES}; do
  say "== ${b}"
  fresh_worktree "${b}" "origin/${b}"
  if grep -q "${NEW_SHA}" .github/workflows/ai-reviewer.yml; then
    say "已是新 SHA，跳过"
    continue
  fi
  edit_pin
  git add -A
  git commit -q -m "test: R2 锁定 SHA 换成修复后的 ${NEW_SHA:0:8}"
  git push -q origin "${b}"
  say "已推送 ${b}"
done

git -C "${ORIG}" worktree remove --force "${WT}" 2>/dev/null || true
say "完成。检查：git -C '${ORIG}' fetch origin && git -C '${ORIG}' show origin/main:.github/workflows/ai-reviewer.yml | grep -n 'ref:'"
