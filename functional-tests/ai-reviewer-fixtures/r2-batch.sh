#!/usr/bin/env bash
# R2 主仓库复测批次：FT-102（#307）、FT-104（#309）、FT-078（#302）。
#
# 用法（在仓库根目录执行；需要已登录 gh，且 r2-pin.sh 已完成）：
#   bash functional-tests/ai-reviewer-fixtures/r2-batch.sh            # 从阶段 1 开始
#   START=3 bash functional-tests/ai-reviewer-fixtures/r2-batch.sh    # 中断后从阶段 3 继续
#
# 阶段：
#   1 FT-102：在 PR #304 评论 `@codesentinel-review-bot help`
#   2 FT-104 准备：往 #304 的分支提交一个可审查文件，让 HEAD 被 R2 的 dist 审查（HEAD 成为“已审查”）
#   3 FT-104：`@ai-reviewer pause` → `@ai-reviewer review`（此时 HEAD 已审查）→ `@ai-reviewer resume`
#   4 FT-078：往 #300 的分支一次推送 62 个新文件，等增量审查跑完（R1 只处理了 30 个）
#
# 只做：gh pr comment、往测试分支 git commit / git push（用分离 HEAD 的临时 worktree，不动你当前分支）。不读取、不打印任何 Secret。
# 兼容 macOS bash 3.2。
set -euo pipefail

REPO="CodesSentinels/ai-reviewer-test"
ORIG="$(git rev-parse --show-toplevel)"
WT="${WT:-/tmp/ft-r2-batch-wt}"
LOG="${LOG:-/tmp/ft-r2-batch.log}"
START="${START:-1}"
BR_SAT="test/ai-reviewer-develop-functional-20261008-b"   # PR #304
BR_MAIN="test/ai-reviewer-develop-functional-20261008"    # PR #300
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

post() {   # $1 = PR 号  $2 = 评论内容  $3 = 之后等待秒数
  printf '%s' "$2" > /tmp/ft-r2-cmd.txt
  local url
  url="$(gh pr comment "$1" --repo "${REPO}" --body-file /tmp/ft-r2-cmd.txt)"
  rm -f /tmp/ft-r2-cmd.txt
  say "已评论 PR #$1: $2 → ${url}"
  sleep "${3:-60}"
}

detached_worktree() {   # $1 = origin/<分支>
  rm -rf "${WT}"
  git -C "${ORIG}" worktree prune
  git -C "${ORIG}" worktree add -q --detach "${WT}" "$1"
  cd "${WT}"
}

wait_run() {   # 等待当前 HEAD 的 pull_request run 完成（最多 25 分钟）
  local sha i st
  sha="$(git rev-parse HEAD)"
  say "等待 run（head ${sha}）…"
  for i in $(seq 1 150); do
    sleep 10
    st="$(gh api "repos/${REPO}/actions/runs?head_sha=${sha}&event=pull_request" --jq '.workflow_runs[0]|"\(.id) \(.status) \(.conclusion)"' 2>/dev/null || true)"
    case "${st}" in
      *" completed "*) say "run 完成: ${st}"; return 0 ;;
    esac
  done
  say "等待超时，请到 Actions 页面确认。"
}

[ "${START}" = "1" ] && : > "${LOG}"
git -C "${ORIG}" fetch -q origin

if [ "${START}" -le 1 ]; then
  say "== 阶段 1：FT-102（真实 bot login @codesentinel-review-bot）"
  post 304 '@codesentinel-review-bot help' 70
fi

if [ "${START}" -le 2 ]; then
  say "== 阶段 2：FT-104 准备——提交可审查文件，让 HEAD 被审查"
  detached_worktree "origin/${BR_SAT}"
  mkdir -p functional-tests/ai-reviewer-fixtures/workspace/noise
  cat > functional-tests/ai-reviewer-fixtures/workspace/noise/r2-head-probe.ts <<'EOF'
export function headProbe(values: number[]): number {
  return values[values.length] / values.length;
}
EOF
  git add -A
  git status --short
  git commit -q -m "test: R2 新增 noise/r2-head-probe.ts，让 HEAD 被审查（FT-104 准备）"
  git push -q origin "HEAD:${BR_SAT}"
  say "已推送 ${BR_SAT}"
  wait_run
fi

if [ "${START}" -le 3 ]; then
  say "== 阶段 3：FT-104——暂停后 HEAD 已审查时发 review"
  post 304 '@ai-reviewer pause' 50
  post 304 '@ai-reviewer review' 90
  post 304 '@ai-reviewer resume' 50
fi

if [ "${START}" -le 4 ]; then
  say "== 阶段 4：FT-078——一次推送 62 个新文件"
  detached_worktree "origin/${BR_MAIN}"
  d=functional-tests/ai-reviewer-fixtures/workspace/r2-many
  mkdir -p "${d}"
  i=1
  while [ "${i}" -le 62 ]; do
    n="$(printf '%03d' "${i}")"
    cat > "${d}/r2-file-${n}.ts" <<EOF
// R2 FT-078：第 ${i} 个文件
export function item${n}(list: number[]): number {
  const base = list[list.length - ${i}];
  return base / (${i} % 5);
}
EOF
    i=$((i + 1))
  done
  git add -A
  say "新增文件数: $(git status --short | wc -l | tr -d ' ')"
  git commit -q -m "test: R2 一次推送 62 个新文件（FT-078 复测 #302）"
  git push -q origin "HEAD:${BR_MAIN}"
  say "已推送 ${BR_MAIN}"
  wait_run
fi

git -C "${ORIG}" worktree remove --force "${WT}" 2>/dev/null || true
say "全部阶段完成。请告诉 Claude。（日志: ${LOG}）"
