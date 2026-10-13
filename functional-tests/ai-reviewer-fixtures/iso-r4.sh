#!/usr/bin/env bash
# R4 隔离环境抽样回归（合入 develop 后的版本）：FT-197（Prettier）、FT-202（安装失败不影响其他工具）、FT-186（shell 功能不回归）、FT-005（缺 key 时 job 失败）。
#
# 用法（在仓库根目录执行；隔离仓库 ai-reviewer-test-iso 的专用 key 与只读 token 仍有效）：
#   bash functional-tests/ai-reviewer-fixtures/iso-r4.sh            # 从阶段 1 开始
#   START=3 bash functional-tests/ai-reviewer-fixtures/iso-r4.sh    # 中断后从阶段 3 继续
#
# 阶段：
#   1 把隔离仓库 main、iso/shell、iso/lint 的锁定 SHA 换成 R4 的新 SHA
#   2 iso/lint：去掉 eslint_version（用默认），新增格式不规范文件        → FT-197（Prettier 在 CI 下应报出发现）
#   3 iso/lint：eslint_version 设为不存在的版本，再新增格式不规范文件     → FT-202（ESLint 降级，Prettier 仍应正常报出发现）
#   4 iso/shell：新增含“假凭据”的文件，shell 仍开启                      → FT-186（shell 功能不回归；脱敏由单测证明）
#   5 新分支 iso/r4-nokey：OPENAI_API_KEY 映射为空，创建 PR            → FT-005（预期 job 红色失败，注解里有 Review not performed）
#
# 只操作隔离仓库；不读取、不打印 Secret；会 git commit / git push（你本人账号）。兼容 macOS bash 3.2。
set -euo pipefail

ISO_REPO="${ISO_REPO:-CodesSentinels/ai-reviewer-test-iso}"
OLD_SHA="${OLD_SHA:-b73adc3e2630bf70241298e515b59bfc5d727917}"
NEW_SHA="${NEW_SHA:-24c87694013c9e5655a920404e582123cbde09fd}"
WT="${WT:-/tmp/ft-iso-r4-wt}"
LOG="${LOG:-/tmp/ft-iso-r4.log}"
START="${START:-1}"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

clone_at() {   # $1 = 分支
  # 上一轮循环的当前目录就在 ${WT} 里，先离开再删，否则后面的 git 会报“无法读取当前工作目录”
  cd /tmp
  rm -rf "${WT}"
  gh repo clone "${ISO_REPO}" "${WT}" -- -q
  cd "${WT}"
  git checkout -q "$1"
}

edit_pin() {
  # 不依赖旧 SHA 是哪一个：各分支可能停在不同轮次的 SHA（例如 main 已是 R3，iso/shell 还是 R2），
  # 直接把 ai-reviewer 那处 checkout 的 ref 换成新 SHA。
  python3 - "${NEW_SHA}" <<'PY2'
import re, sys
new = sys.argv[1]
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
if new in s:
    print('already pinned')
    sys.exit(0)
out, n = re.subn(r'(repository: CodesSentinels/ai-reviewer\n\s+ref: )[0-9a-f]{40}', lambda m: m.group(1) + new, s, count=1)
assert n == 1, 'ai-reviewer checkout ref not found'
open(p, 'w', encoding='utf-8').write(out)
PY2
}

set_input() {   # $1 = 输入名  $2 = 值；值为 __REMOVE__ 时删除该行
  python3 - "$1" "$2" <<'PY'
import re, sys
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
name, val = sys.argv[1], sys.argv[2]
pat = r'^(\s+)' + re.escape(name) + r': .*\n'
if val == '__REMOVE__':
    s = re.sub(pat, '', s, count=1, flags=re.M)
elif re.search(pat, s, flags=re.M):
    s = re.sub(r'^(\s+)' + re.escape(name) + r': .*$', lambda m: m.group(1) + name + ': ' + val, s, count=1, flags=re.M)
else:
    s = re.sub(r'^(\s+)enable_lint_tools: .*$', lambda m: m.group(0) + '\n' + m.group(1) + name + ': ' + val, s, count=1, flags=re.M)
open(p, 'w', encoding='utf-8').write(s)
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
  say "== 阶段 1：隔离仓库换 SHA（${NEW_SHA}）"
  for b in main iso/shell iso/lint; do
    clone_at "${b}"
    if grep -q "${NEW_SHA}" .github/workflows/ai-reviewer.yml; then say "${b} 已是新 SHA，跳过"; continue; fi
    edit_pin
    git add -A
    git commit -q -m "test: R4 锁定 SHA 换成修复后的 ${NEW_SHA:0:8}"
    git push -q origin "${b}"
    say "已推送 ${b}"
  done
  say "等待 120 秒，让换 SHA 触发的 run 结束，再推下一个提交（连续 push 会让合并提交滞后）"
  sleep 120
fi

if [ "${START}" -le 2 ]; then
  say "== 阶段 2：FT-197——eslint 用默认版本，Prettier 应报出格式问题"
  clone_at iso/lint
  set_input eslint_version __REMOVE__
  mkdir -p style
  cat > style/ugly-r4.ts <<'XEOF'
export   function   total( a:number,b:number ){
return a+b
}
export const   cfg={a:1,
   b:2}
XEOF
  git add -A
  git commit -q -m "test: R4 去掉 eslint_version 并新增格式不规范文件（FT-197 复测 #317）"
  git push -q origin iso/lint
  wait_run
fi

if [ "${START}" -le 3 ]; then
  say "== 阶段 3：FT-202——eslint 版本不存在，Prettier 仍应正常"
  clone_at iso/lint
  set_input eslint_version '"9.999.999"'
  mkdir -p style
  cat > style/ugly-r4b.ts <<'XEOF'
export   function   product( a:number,b:number ){
return a*b
}
export const   limits={min:0,
   max:10}
XEOF
  git add -A
  git commit -q -m "test: R4 eslint 版本不存在并新增格式不规范文件（FT-202 复测 #318）"
  git push -q origin iso/lint
  wait_run
fi

if [ "${START}" -le 4 ]; then
  say "== 阶段 4：FT-186——shell 开启，文件里含假凭据"
  clone_at iso/shell
  mkdir -p app
  cat > app/token-config-r4.ts <<'XEOF'
// 假凭据，仅用于测试，不可用
export const config = {
  openaiKey: "sk-proj-FAKEFAKEFAKEFAKEFAKE1234",
  githubToken: "ghp_FAKEFAKEFAKEFAKEFAKEFAKEFAKE123456",
  endpoint: "https://example.com/api"
};

export function loadConfig(name: string) {
  return (config as Record<string, string>)[name];
}
XEOF
  git add -A
  git commit -q -m "test: R4 新增含假凭据的文件，shell 开启（FT-186 复测 #316）"
  git push -q origin iso/shell
  wait_run
fi

blank_key() {
  python3 -c "
import re
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
new, n = re.subn(r'^(\s+)OPENAI_API_KEY: .*$', lambda m: m.group(1) + 'OPENAI_API_KEY: \"\"', s, count=1, flags=re.M)
assert n == 1, 'OPENAI_API_KEY mapping not found'
open(p, 'w', encoding='utf-8').write(new)
"
}

if [ "${START}" -le 5 ]; then
  say "== 阶段 5：FT-005——OPENAI_API_KEY 映射为空"
  clone_at main
  git checkout -q -B iso/r4-nokey
  blank_key
  mkdir -p app
  cat > app/r4-nokey.ts <<'XEOF'
export function ratio(a: number, b: number): number {
  return a / b;
}
XEOF
  git add -A
  git commit -q -m "test: R4 OPENAI_API_KEY 映射为空并新增可审查文件（FT-005 抽样回归）"
  git push -q -u origin iso/r4-nokey
  if ! gh pr view iso/r4-nokey --repo "${ISO_REPO}" >/dev/null 2>&1; then
    url="$(gh pr create --repo "${ISO_REPO}" --base main --head iso/r4-nokey --title "test: R4 缺少 OPENAI_API_KEY（FT-005，请勿合并）" --body "隔离仓库，OPENAI_API_KEY 映射为空，验证 job 以明确的错误失败。关联 ai-reviewer-test 总回归 Issue #299。")"
    say "已创建 PR: ${url}"
  fi
  wait_run
fi

cd /tmp
say "全部阶段完成。请告诉 Claude。（日志: ${LOG}）"
