#!/usr/bin/env bash
# R4 主仓库抽样回归（合入 develop 后的版本）：FT-128（限流）、FT-055、FT-092、FT-036，加 FT-102/104（命令与暂停后 review）和 FT-078（一次推送 62 个文件）。
#
# 用法（在仓库根目录执行；需要已登录 gh，且 r4-pin.sh 已完成）：
#   bash functional-tests/ai-reviewer-fixtures/r4-batch.sh            # 从阶段 1 开始
#   START=4 bash functional-tests/ai-reviewer-fixtures/r4-batch.sh    # 中断后从阶段 4 继续
#
# 全部在卫星 PR #304（分支 -b）上进行，每次 push 都等 run 跑完再推下一次（连续 push 会让合并提交滞后，复测无效）。
#
# 阶段：
#   1 FT-128：等 70 秒让窗口清空，12 秒内连发 12 条 `@ai-reviewer help`
#   2 FT-055 准备：提交 noise/r4-dup.ts（4~5 个独立缺陷），等自动审查发布评论
#   3 FT-055：再提交一个被路径过滤的 .md（HEAD 不会被记为已审查），然后 `@ai-reviewer full review`，预期不重复发布
#   4 FT-092 准备：workflow 设 max_review_comments=1 并提交 noise/r4-trunc.ts，自动审查只发 1 条，其余被截断
#   5 FT-092：还原 workflow（只改 workflow，被过滤），然后 `@ai-reviewer full review`（上限 20），预期补发被截断的问题、不重复已发的
#   6 FT-036 准备：提交格式不规范的 noise/r4-format.ts，等自动审查
#   8 FT-102/104：提交可审查文件让 HEAD 被审查；评论真实 bot login；pause → review（HEAD 已审查）→ resume
#   9 FT-078：往 #300 的分支一次推送 62 个新文件，等增量审查跑完
#   10~11 FT-092 重做：第一次 R4 里模型把 4 个问题合并成一条评论，没有触发截断；换成 4 个相互独立的缺陷再测（`START=10` 只跑这两个阶段）
#   7 FT-036：再提交仅格式化（引号、分号、缩进、空格）的版本，预期判 APPROVED、没有新评论
#
# 只做：gh pr comment、往测试分支 git commit / git push（分离 HEAD 的临时 worktree，不动你当前分支）。不读取、不打印任何 Secret。
# 兼容 macOS bash 3.2。
set -euo pipefail

REPO="CodesSentinels/ai-reviewer-test"
ORIG="$(git rev-parse --show-toplevel)"
WT="${WT:-/tmp/ft-r4-batch-wt}"
LOG="${LOG:-/tmp/ft-r4-batch.log}"
START="${START:-1}"
BR="test/ai-reviewer-develop-functional-20261008-b"   # PR #304
BR_MAIN="test/ai-reviewer-develop-functional-20261008"  # PR #300
PR=304
NOISE="functional-tests/ai-reviewer-fixtures/workspace/noise"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

post() {   # $1 = 评论内容  $2 = 之后等待秒数
  printf '%s' "$1" > /tmp/ft-r4-cmd.txt
  local url
  url="$(gh pr comment "${PR}" --repo "${REPO}" --body-file /tmp/ft-r4-cmd.txt)"
  rm -f /tmp/ft-r4-cmd.txt
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
  say "== 阶段 2：FT-055 准备——提交 r4-dup.ts"
  fresh
  mkdir -p "${NOISE}"
  cat > "${NOISE}/r4-dup.ts" <<'EOF'
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
  commit_push_wait "test: R4 新增 noise/r4-dup.ts（FT-055 准备）"
fi

if [ "${START}" -le 3 ]; then
  say "== 阶段 3：FT-055——HEAD 变成未审查后发 full review"
  fresh
  printf '# R4 note\n\n仅用于让 HEAD 变化（.md 被路径过滤，不记为已审查）。\n' > "${NOISE}/r4-note.md"
  commit_push_wait "test: R4 新增被过滤的 .md，让 HEAD 变成未审查（FT-055）"
  post '@ai-reviewer full review' 200
fi

if [ "${START}" -le 4 ]; then
  say "== 阶段 4：FT-092 准备——max_review_comments=1，提交 r4-trunc.ts"
  fresh
  set_max_comments '"1"'
  cat > "${NOISE}/r4-trunc.ts" <<'EOF'
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
  commit_push_wait "test: R4 max_review_comments=1 并新增 noise/r4-trunc.ts（FT-092 准备）"
fi

if [ "${START}" -le 5 ]; then
  say "== 阶段 5：FT-092——还原 workflow 后发 full review（上限 20）"
  fresh
  set_max_comments __REMOVE__
  commit_push_wait "test: R4 还原 max_review_comments（只改 workflow，被过滤）"
  post '@ai-reviewer full review' 200
fi

if [ "${START}" -le 6 ]; then
  say "== 阶段 6：FT-036 准备——提交格式不规范的 r4-format.ts"
  fresh
  cat > "${NOISE}/r4-format.ts" <<'EOF'
export const user_name = 'ada'
export function Add_Numbers(a:number,b:number){
    return a+b
}
export const greeting_text = "hello"  ;
EOF
  commit_push_wait "test: R4 新增格式不规范的 noise/r4-format.ts（FT-036 准备）"
fi

if [ "${START}" -le 7 ]; then
  say "== 阶段 7：FT-036——仅格式化的改动（逻辑与标识符完全不变）"
  fresh
  cat > "${NOISE}/r4-format.ts" <<'EOF'
export const user_name = "ada";
export function Add_Numbers(a: number, b: number) {
  return a + b;
}
export const greeting_text = "hello";
EOF
  commit_push_wait "test: R4 对 r4-format.ts 仅做格式化（引号、分号、缩进、空格），逻辑不变（FT-036）"
fi

if [ "${START}" -le 8 ]; then
  say "== 阶段 8：FT-102/104——命令与暂停后 review"
  fresh
  cat > "${NOISE}/r4-head-probe.ts" <<'XEOF'
export function headProbe(values: number[]): number {
  return values[values.length] / values.length;
}
XEOF
  commit_push_wait "test: R4 新增 noise/r4-head-probe.ts，让 HEAD 被审查（FT-104 准备）"
  post '@codesentinel-review-bot help' 70
  post '@ai-reviewer pause' 50
  post '@ai-reviewer review' 90
  post '@ai-reviewer resume' 50
fi

if [ "${START}" -le 9 ]; then
  say "== 阶段 9：FT-078——一次推送 62 个新文件（PR #300 的分支）"
  cd /tmp
  rm -rf "${WT}"
  git -C "${ORIG}" worktree prune
  git -C "${ORIG}" fetch -q origin
  git -C "${ORIG}" worktree add -q --detach "${WT}" "origin/${BR_MAIN}"
  cd "${WT}"
  d=functional-tests/ai-reviewer-fixtures/workspace/r4-many
  mkdir -p "${d}"
  i=1
  while [ "${i}" -le 62 ]; do
    n="$(printf '%03d' "${i}")"
    cat > "${d}/r4-file-${n}.ts" <<XEOF
// R4 FT-078：第 ${i} 个文件
export function item${n}(list: number[]): number {
  const base = list[list.length - ${i}];
  return base / (${i} % 5);
}
XEOF
    i=$((i + 1))
  done
  git add -A
  say "新增文件数: $(git status --short | wc -l | tr -d ' ')"
  git commit -q -m "test: R4 一次推送 62 个新文件（FT-078 抽样回归）"
  git push -q origin "HEAD:${BR_MAIN}"
  say "已推送 ${BR_MAIN}"
  PR=300
  wait_run
fi

if [ "${START}" -le 10 ]; then
  say "== 阶段 10：FT-092 重做（第一次被模型合并成一条评论，没有触发截断）——4 个相互独立的缺陷，max_review_comments=1"
  fresh
  set_max_comments '"1"'
  cat > "${NOISE}/r4b-trunc.ts" <<'XEOF'
export function splitWords(text: string): string[] {
  return text.split(" ").map((w) => w.trim())[text.length];
}

export function averageOf(values: number[]): number {
  return values.reduce((a, b) => a + b, 0) / (values.length - 1);
}

export function renderGreeting(userHtml: string): string {
  return "<div>" + userHtml + "</div>";
}

export const REFRESH_SECRET = "rf_live_9f8e7d6c5b4a3210";
XEOF
  commit_push_wait "test: R4 max_review_comments=1 并新增 noise/r4b-trunc.ts（FT-092 重做准备）"
fi

if [ "${START}" -le 11 ]; then
  say "== 阶段 11：FT-092 重做——还原 workflow 后发 full review（上限 20）"
  fresh
  set_max_comments __REMOVE__
  commit_push_wait "test: R4 还原 max_review_comments（只改 workflow，被过滤）"
  post '@ai-reviewer full review' 200
fi

cd /tmp
git -C "${ORIG}" worktree remove --force "${WT}" 2>/dev/null || true
say "全部阶段完成。请告诉 Claude。（日志: ${LOG}）"
