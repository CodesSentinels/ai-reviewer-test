#!/usr/bin/env bash
# R3 主仓库复测批次：FT-128（#308 限流）、FT-055（#303 同一问题不重复）、FT-092（#305 截断后补发且不重复）、FT-036（#301 仅格式化不评论）。
#
# 用法（在仓库根目录执行；需要已登录 gh，且 r3-pin.sh 已完成）：
#   bash functional-tests/ai-reviewer-fixtures/r3-batch.sh            # 从阶段 1 开始
#   START=4 bash functional-tests/ai-reviewer-fixtures/r3-batch.sh    # 中断后从阶段 4 继续
#
# 全部在卫星 PR #304（分支 -b）上进行，每次 push 都等 run 跑完再推下一次（连续 push 会让合并提交滞后，复测无效）。
#
# 阶段：
#   1 FT-128：等 70 秒让窗口清空，12 秒内连发 12 条 `@ai-reviewer help`
#   2 FT-055 准备：提交 noise/r3-dup.ts（4~5 个独立缺陷），等自动审查发布评论
#   3 FT-055：再提交一个被路径过滤的 .md（HEAD 不会被记为已审查），然后 `@ai-reviewer full review`，预期不重复发布
#   4 FT-092 准备：workflow 设 max_review_comments=1 并提交 noise/r3-trunc.ts，自动审查只发 1 条，其余被截断
#   5 FT-092：还原 workflow（只改 workflow，被过滤），然后 `@ai-reviewer full review`（上限 20），预期补发被截断的问题、不重复已发的
#   6 FT-036 准备：提交格式不规范的 noise/r3-format.ts，等自动审查
#   7 FT-036：再提交仅格式化（引号、分号、缩进、空格）的版本，预期判 APPROVED、没有新评论
#
# 只做：gh pr comment、往测试分支 git commit / git push（分离 HEAD 的临时 worktree，不动你当前分支）。不读取、不打印任何 Secret。
# 兼容 macOS bash 3.2。
set -euo pipefail

REPO="CodesSentinels/ai-reviewer-test"
ORIG="$(git rev-parse --show-toplevel)"
WT="${WT:-/tmp/ft-r3-batch-wt}"
LOG="${LOG:-/tmp/ft-r3-batch.log}"
START="${START:-1}"
BR="test/ai-reviewer-develop-functional-20261008-b"   # PR #304
PR=304
NOISE="functional-tests/ai-reviewer-fixtures/workspace/noise"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

post() {   # $1 = 评论内容  $2 = 之后等待秒数
  printf '%s' "$1" > /tmp/ft-r3-cmd.txt
  local url
  url="$(gh pr comment "${PR}" --repo "${REPO}" --body-file /tmp/ft-r3-cmd.txt)"
  rm -f /tmp/ft-r3-cmd.txt
  say "已评论 PR #${PR}: $1 → ${url}"
  sleep "${2:-5}"
}

fresh() {   # 每次都从最新的远端分支起一个分离 HEAD 的临时 worktree
  cd /tmp
  rm -rf "${WT}"
  git -C "${ORIG}" worktree prune
  git -C "${ORIG}" fetch -q origin
  git -C "${ORIG}" worktree add -q --detach "${WT}" "origin/${BR}"
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
      *" completed "*) say "run 完成: ${st}"; sleep 15; return 0 ;;
    esac
  done
  say "等待超时，请到 Actions 页面确认。"
}

commit_push_wait() {   # $1 = commit 消息
  git add -A
  git status --short
  git commit -q -m "$1"
  git push -q origin "HEAD:${BR}"
  say "已推送: $1"
  wait_run
}

set_max_comments() {   # $1 = 值；值为 __REMOVE__ 时删除该行
  python3 - "$1" <<'PY'
import re, sys
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
val = sys.argv[1]
pat = r'^(\s+)max_review_comments: .*\n'
if val == '__REMOVE__':
    s = re.sub(pat, '', s, count=1, flags=re.M)
elif re.search(pat, s, flags=re.M):
    s = re.sub(r'^(\s+)max_review_comments: .*$', lambda m: m.group(1) + 'max_review_comments: ' + val, s, count=1, flags=re.M)
else:
    s = re.sub(r'^(\s+)enable_semgrep: .*$', lambda m: m.group(0) + '\n' + m.group(1) + 'max_review_comments: ' + val, s, count=1, flags=re.M)
open(p, 'w', encoding='utf-8').write(s)
PY
}

[ "${START}" = "1" ] && : > "${LOG}"

if [ "${START}" -le 1 ]; then
  say "== 阶段 1：FT-128 限流——等 70 秒让窗口清空，再 12 秒内连发 12 条"
  sleep 70
  i=1
  while [ "${i}" -le 12 ]; do
    post '@ai-reviewer help' 1
    i=$((i + 1))
  done
  say "等待 90 秒让所有 run 结束"
  sleep 90
fi

if [ "${START}" -le 2 ]; then
  say "== 阶段 2：FT-055 准备——提交 r3-dup.ts"
  fresh
  mkdir -p "${NOISE}"
  cat > "${NOISE}/r3-dup.ts" <<'EOF'
export function divideAll(values: number[], by: number): number[] {
  return values.map((v) => v / by);
}

export function lastOf(list: string[]): string {
  return list[list.length];
}

export function buildQuery(name: string): string {
  return "SELECT * FROM users WHERE name = '" + name + "'";
}

export const SERVICE_TOKEN = "tok_live_1234567890abcdef";

export function fetchAll(urls: string[]): Promise<unknown[]> {
  return urls.map(async (u) => (await fetch(u)).json());
}
EOF
  commit_push_wait "test: R3 新增 noise/r3-dup.ts（FT-055 准备）"
fi

if [ "${START}" -le 3 ]; then
  say "== 阶段 3：FT-055——HEAD 变成未审查后发 full review"
  fresh
  printf '# R3 note\n\n仅用于让 HEAD 变化（.md 被路径过滤，不记为已审查）。\n' > "${NOISE}/r3-note.md"
  commit_push_wait "test: R3 新增被过滤的 .md，让 HEAD 变成未审查（FT-055）"
  post '@ai-reviewer full review' 200
fi

if [ "${START}" -le 4 ]; then
  say "== 阶段 4：FT-092 准备——max_review_comments=1，提交 r3-trunc.ts"
  fresh
  set_max_comments '"1"'
  cat > "${NOISE}/r3-trunc.ts" <<'EOF'
export function loadAll(urls: string[]): Promise<unknown[]> {
  return urls.map(async (url) => (await fetch(url)).json());
}

export function lastItem(items: string[]): string {
  return items[items.length];
}

export function findUser(db: {query: (sql: string) => unknown}, name: string) {
  return db.query("SELECT * FROM users WHERE name = '" + name + "'");
}

export const API_TOKEN = "tok_live_abcdef1234567890";
EOF
  commit_push_wait "test: R3 max_review_comments=1 并新增 noise/r3-trunc.ts（FT-092 准备）"
fi

if [ "${START}" -le 5 ]; then
  say "== 阶段 5：FT-092——还原 workflow 后发 full review（上限 20）"
  fresh
  set_max_comments __REMOVE__
  commit_push_wait "test: R3 还原 max_review_comments（只改 workflow，被过滤）"
  post '@ai-reviewer full review' 200
fi

if [ "${START}" -le 6 ]; then
  say "== 阶段 6：FT-036 准备——提交格式不规范的 r3-format.ts"
  fresh
  cat > "${NOISE}/r3-format.ts" <<'EOF'
export const user_name = 'ada'
export function Add_Numbers(a:number,b:number){
    return a+b
}
export const greeting_text = "hello"  ;
EOF
  commit_push_wait "test: R3 新增格式不规范的 noise/r3-format.ts（FT-036 准备）"
fi

if [ "${START}" -le 7 ]; then
  say "== 阶段 7：FT-036——仅格式化的改动（逻辑与标识符完全不变）"
  fresh
  cat > "${NOISE}/r3-format.ts" <<'EOF'
export const user_name = "ada";
export function Add_Numbers(a: number, b: number) {
  return a + b;
}
export const greeting_text = "hello";
EOF
  commit_push_wait "test: R3 对 r3-format.ts 仅做格式化（引号、分号、缩进、空格），逻辑不变（FT-036）"
fi

cd /tmp
git -C "${ORIG}" worktree remove --force "${WT}" 2>/dev/null || true
say "全部阶段完成。请告诉 Claude。（日志: ${LOG}）"
