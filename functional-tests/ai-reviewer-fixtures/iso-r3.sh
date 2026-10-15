#!/usr/bin/env bash
# R3 隔离环境复测：FT-005（#311 缺少 OPENAI_API_KEY 时 job 以明确的错误失败）。
#
# 用法（在仓库根目录执行；隔离仓库 ai-reviewer-test-iso 的专用 key 与只读 token 仍有效）：
#   bash functional-tests/ai-reviewer-fixtures/iso-r3.sh            # 从阶段 1 开始
#   START=2 bash functional-tests/ai-reviewer-fixtures/iso-r3.sh    # 中断后从阶段 2 继续
#
# 阶段：
#   1 把隔离仓库 main 的锁定 SHA 换成 R3 的新 SHA
#   2 新建分支 iso/r3-nokey：workflow 里把 OPENAI_API_KEY 映射成空字符串，并提交一个可审查文件，创建 PR
#     预期：job 红色失败，日志/注解里有 “Review not performed … OPENAI_API_KEY”
#
# 只操作隔离仓库；不读取、不打印 Secret；会 git commit / git push / gh pr create（你本人账号）。兼容 macOS bash 3.2。
set -euo pipefail

ISO_REPO="${ISO_REPO:-CodesSentinels/ai-reviewer-test-iso}"
OLD_SHA="${OLD_SHA:-c96cd53e0c1a23abf85ecb21c5a0e90a255333c5}"
NEW_SHA="${NEW_SHA:-b73adc3e2630bf70241298e515b59bfc5d727917}"
WT="${WT:-/tmp/ft-iso-r3-wt}"
LOG="${LOG:-/tmp/ft-iso-r3.log}"
START="${START:-1}"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

clone_at() {   # $1 = 分支
  cd /tmp
  rm -rf "${WT}"
  gh repo clone "${ISO_REPO}" "${WT}" -- -q
  cd "${WT}"
  git checkout -q "$1"
}

edit_pin() {
  python3 - "${OLD_SHA}" "${NEW_SHA}" <<'PY'
import sys
old, new = sys.argv[1], sys.argv[2]
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
if new in s:
    print('already pinned')
    sys.exit(0)
assert old in s, 'old SHA not found'
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
}

blank_key() {
  python3 <<'PY'
import re
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
new, n = re.subn(r'^(\s+)OPENAI_API_KEY: .*$', lambda m: m.group(1) + 'OPENAI_API_KEY: ""', s, count=1, flags=re.M)
assert n == 1, 'OPENAI_API_KEY mapping not found'
open(p, 'w', encoding='utf-8').write(new)
PY
}

wait_run() {
  local sha i st
  sha="$(git rev-parse HEAD)"
  say "等待 run（head ${sha}）…"
  for i in $(seq 1 90); do
    sleep 10
    st="$(gh api "repos/${ISO_REPO}/actions/runs?head_sha=${sha}" --jq '.workflow_runs[0]|"\(.id) \(.status) \(.conclusion)"' 2>/dev/null || true)"
    case "${st}" in
      *" completed "*) say "run 完成: ${st}"; return 0 ;;
    esac
  done
  say "等待超时，请到 Actions 页面确认。"
}

[ "${START}" = "1" ] && : > "${LOG}"

if [ "${START}" -le 1 ]; then
  say "== 阶段 1：隔离仓库 main 换 SHA（${NEW_SHA}）"
  clone_at main
  if grep -q "${NEW_SHA}" .github/workflows/ai-reviewer.yml; then
    say "main 已是新 SHA，跳过"
  else
    edit_pin
    git add -A
    git commit -q -m "test: R3 锁定 SHA 换成修复后的 ${NEW_SHA:0:8}"
    git push -q origin main
    say "已推送 main"
  fi
fi

if [ "${START}" -le 2 ]; then
  say "== 阶段 2：FT-005——OPENAI_API_KEY 映射为空"
  clone_at main
  git checkout -q -B iso/r3-nokey
  blank_key
  mkdir -p app
  cat > app/r3-nokey.ts <<'XEOF'
export function ratio(a: number, b: number): number {
  return a / b;
}
XEOF
  git add -A
  git commit -q -m "test: R3 OPENAI_API_KEY 映射为空并新增可审查文件（FT-005 复测 #311）"
  git push -q -u origin iso/r3-nokey
  if ! gh pr view iso/r3-nokey --repo "${ISO_REPO}" >/dev/null 2>&1; then
    url="$(gh pr create --repo "${ISO_REPO}" --base main --head iso/r3-nokey --title "test: R3 缺少 OPENAI_API_KEY（FT-005，请勿合并）" --body "隔离仓库，OPENAI_API_KEY 映射为空，验证 job 以明确的错误失败。关联 ai-reviewer-test 总回归 Issue #299。")"
    say "已创建 PR: ${url}"
  fi
  wait_run
fi

cd /tmp
say "完成。请告诉 Claude。（日志: ${LOG}）"
