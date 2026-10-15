#!/usr/bin/env bash
# R6（#325 修复后的版本 acc61bb5 上）重放 Phase 1~3：复测 FT-093/094，并与 R5 的 Phase 1~3 结果对比。
#
# 做法：新建分支 test/r6-lane（从 main，main 的 workflow 已固定 24c87694），把 R1 当时三个 Phase 提交里的
# workspace 夹具逐个重放成三次推送，开一个新 PR（base=main），每次推送都等 run 结束再推下一次。
#   Phase 1：4c47d40a 的 workspace（28 个夹具文件）→ 创建 PR，首次审查
#   Phase 2：83140bc0 的 workspace（增量审查、跨文件签名变化、增删改名、仅格式化）→ 增量审查
#   Phase 3：88bf7db4 的 workspace（回退修改、被过滤文件、超评论上限、提示词注入、大 diff、重命名）→ 增量审查
#   最后：`@ai-reviewer full review`
# 不包含 cases/*.md 等文档（.md 本来就不审查，也不需要出现在 PR 里）。
#
# 用法（在仓库根目录执行；需要已登录 gh）：
#   bash functional-tests/ai-reviewer-fixtures/r6-lane.sh            # 从阶段 1 开始
#   START=3 bash functional-tests/ai-reviewer-fixtures/r6-lane.sh    # 中断后从阶段 3 继续
#
# 只做：git commit / git push（分离 HEAD 的临时 worktree，不动你当前分支）、gh pr create、gh pr comment。
# 不读取、不打印任何 Secret。兼容 macOS bash 3.2。
set -euo pipefail

REPO="CodesSentinels/ai-reviewer-test"
ORIG="$(git rev-parse --show-toplevel)"
WT="${WT:-/tmp/ft-r6-lane-wt}"
LOG="${LOG:-/tmp/ft-r6-lane.log}"
START="${START:-1}"
BR="test/r6-lane"
P1="4c47d40a"
P2="83140bc0"
P3="88bf7db4"
WS="functional-tests/ai-reviewer-fixtures/workspace"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

wait_run() {   # 等待当前 HEAD 的 pull_request run 完成（最多 30 分钟）
  local sha i st
  sha="$(git rev-parse HEAD)"
  say "等待 run（head ${sha}）…"
  for i in $(seq 1 180); do
    sleep 10
    st="$(gh api "repos/${REPO}/actions/runs?head_sha=${sha}&event=pull_request" --jq '.workflow_runs[0]|"\(.id) \(.status) \(.conclusion)"' 2>/dev/null || true)"
    case "${st}" in
      *" completed "*) say "run 完成: ${st}"; sleep 20; return 0 ;;
    esac
  done
  say "等待超时，请到 Actions 页面确认。"
}

fresh_from() {   # $1 = 起点（origin/main 或 origin/<分支>）
  cd /tmp
  rm -rf "${WT}"
  git -C "${ORIG}" worktree prune
  git -C "${ORIG}" fetch -q origin
  git -C "${ORIG}" worktree add -q --detach "${WT}" "$1"
  cd "${WT}"
}

replay_phase() {   # $1 = R1 的 Phase 提交  $2 = commit 消息
  # 以该提交里的 workspace 目录为准（整目录替换，保持与 R1 当时的文件状态一致）
  rm -rf "${WS}"
  git checkout "$1" -- "${WS}"
  git add -A
  git status --short | tail -3
  git commit -q -m "$2"
}

[ "${START}" = "1" ] && : > "${LOG}"
git -C "${ORIG}" fetch -q origin
for c in "${P1}" "${P2}" "${P3}"; do
  git -C "${ORIG}" cat-file -e "${c}^{commit}" || { say "找不到提交 ${c}，请先 git fetch"; exit 1; }
done

if [ "${START}" -le 1 ]; then
  say "== 阶段 1：Phase 1（首次审查，创建 PR）"
  fresh_from "origin/main"
  say "main 当前固定的 SHA: $(grep -E '^\s+ref: ' .github/workflows/ai-reviewer.yml | tr -d ' ')"
  replay_phase "${P1}" "test: R6 Phase 1 夹具（#325 修复后的版本 acc61bb5）"
  # worktree 是分离 HEAD；git checkout <提交> -- 会带入当时的 workspace，需要把无关文件排除
  git push -q origin "HEAD:refs/heads/${BR}"
  say "已推送 ${BR}"
  if ! gh pr view "${BR}" --repo "${REPO}" >/dev/null 2>&1; then
    url="$(gh pr create --repo "${REPO}" --base main --head "${BR}" --title "test: R6 补跑完整回归（24c87694，请勿合并）" --body "在 #325 修复后的版本 acc61bb5 上重放 Phase 1~3，复测 FT-093/094。关联总回归 Issue #299。")"
    say "已创建 PR: ${url}"
  fi
  wait_run
fi

if [ "${START}" -le 2 ]; then
  say "== 阶段 2：Phase 2（增量审查）"
  fresh_from "origin/${BR}"
  replay_phase "${P2}" "test: R6 Phase 2 夹具（增量审查、跨文件签名变化、增删改名、仅格式化）"
  git push -q origin "HEAD:refs/heads/${BR}"
  say "已推送 Phase 2"
  wait_run
fi

if [ "${START}" -le 3 ]; then
  say "== 阶段 3：Phase 3（回退、被过滤文件、超评论上限、注入、大 diff）"
  fresh_from "origin/${BR}"
  replay_phase "${P3}" "test: R6 Phase 3 夹具（回退修改、被过滤文件、超评论上限、提示词注入、大 diff、重命名）"
  git push -q origin "HEAD:refs/heads/${BR}"
  say "已推送 Phase 3"
  wait_run
fi

if [ "${START}" -le 4 ]; then
  say "== 阶段 4：full review"
  printf '%s' '@ai-reviewer full review' > /tmp/ft-r6-cmd.txt
  url="$(gh pr comment "${BR}" --repo "${REPO}" --body-file /tmp/ft-r6-cmd.txt)"
  rm -f /tmp/ft-r6-cmd.txt
  say "已评论: ${url}"
  say "等待 240 秒让 full review 结束"
  sleep 240
fi

cd /tmp
git -C "${ORIG}" worktree remove --force "${WT}" 2>/dev/null || true
say "全部阶段完成。请告诉 Claude。（日志: ${LOG}）"
