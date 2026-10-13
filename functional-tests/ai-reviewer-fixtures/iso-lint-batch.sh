#!/usr/bin/env bash
# 隔离环境 lint 阶段（FT-191~202）：在 ai-reviewer-test-iso 的同一个 PR（分支 iso/lint）上连续提交 7 个阶段，每个阶段等 workflow 跑完再继续。
#
# 用法：
#   bash functional-tests/ai-reviewer-fixtures/iso-lint-batch.sh          # 从阶段 1 开始
#   START=4 bash functional-tests/ai-reviewer-fixtures/iso-lint-batch.sh  # 从阶段 4 继续（中断后）
#
# 阶段：
#   1 开启 lint 总开关（eslint/biome/tsc 默认开，prettier/semgrep 不设置，验证默认关闭）+ lint 夹具     → FT-191/193/194/196/198
#   2 删除 eslint.config.js 与 tsconfig.json                                                           → FT-192/195
#   3 恢复两个配置，显式开启 prettier + 格式不规范文件                                                  → FT-197
#   4 显式开启 semgrep（默认规则 p/default）+ 有漏洞的文件                                              → FT-199
#   5 semgrep_config 指向仓库内自定义规则                                                               → FT-200
#   6 显式指定 eslint_version / prettier_version                                                        → FT-201
#   7 把 eslint_version 设为不存在的版本，安装失败                                                      → FT-202
#
# 只操作隔离仓库；不读取、不打印 Secret；会执行 git commit / git push / gh pr create（你本人账号）。
# FT-203（工具超时）无法靠 PR 稳定复现，使用单测证据，不在此脚本内。
# 兼容 macOS bash 3.2。
set -euo pipefail

ISO_REPO="${ISO_REPO:-CodesSentinels/ai-reviewer-test-iso}"
ORIG="$(git rev-parse --show-toplevel)"
FIX="${ORIG}/functional-tests/ai-reviewer-fixtures/workspace"
WT="${WT:-/tmp/ft-iso-lint-wt}"
BRANCH="iso/lint"
LOG="${LOG:-/tmp/ft-iso-lint.log}"
START="${START:-1}"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

set_input() {   # $1 = 输入名  $2 = 值（已存在则替换，否则插在 enable_lint_tools 之后）
  python3 - "$1" "$2" <<'PY'
import re, sys
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
name, val = sys.argv[1], sys.argv[2]
pat = r'^(\s+)' + re.escape(name) + r': .*$'
if re.search(pat, s, flags=re.M):
    s = re.sub(pat, lambda m: m.group(1) + name + ': ' + val, s, count=1, flags=re.M)
else:
    s = re.sub(r'^(\s+)enable_lint_tools: .*$', lambda m: m.group(0) + '\n' + m.group(1) + name + ': ' + val, s, count=1, flags=re.M)
open(p, 'w', encoding='utf-8').write(s)
PY
}

wait_run() {   # 等待当前 HEAD 的 pull_request run 完成（最多 15 分钟）
  local sha i st
  sha="$(git rev-parse HEAD)"
  say "等待 run（head ${sha})…"
  for i in $(seq 1 90); do
    sleep 10
    st="$(gh api "repos/${ISO_REPO}/actions/runs?head_sha=${sha}" --jq '.workflow_runs[0]|"\(.id) \(.status) \(.conclusion)"' 2>/dev/null || true)"
    case "${st}" in
      *" completed "*) say "run 完成: ${st}"; return 0 ;;
    esac
  done
  say "等待超时，请到 Actions 页面确认。"
}

commit_push_wait() {   # $1 = commit 消息
  git add -A
  git status --short
  git commit -q -m "$1"
  git push -q -u origin "${BRANCH}"
  say "已推送: $1"
  if [ -z "${PR_URL:-}" ] && ! gh pr view "${BRANCH}" --repo "${ISO_REPO}" >/dev/null 2>&1; then
    PR_URL="$(gh pr create --repo "${ISO_REPO}" --base main --head "${BRANCH}" --title "test: 隔离环境 lint 阶段（FT-191~202，请勿合并）" --body "隔离仓库，lint 工具逐项叠加，无业务 Secret。关联 ai-reviewer-test 总回归 Issue #299。")"
    say "已创建 PR: ${PR_URL}"
  fi
  wait_run
}

if [ "${START}" = "1" ]; then
  : > "${LOG}"
  rm -rf "${WT}"
  gh repo clone "${ISO_REPO}" "${WT}" -- -q
  cd "${WT}"
  git checkout -q main
  git checkout -q -B "${BRANCH}"
else
  cd "${WT}"
  git checkout -q "${BRANCH}"
  git pull -q origin "${BRANCH}" || true
fi

stage() { [ "${START}" -le "$1" ]; }

if stage 1; then
  say "== 阶段 1：开启 lint 总开关（eslint/biome/tsc），prettier/semgrep 不设置（默认）"
  set_input enable_lint_tools true
  mkdir -p lint utils
  cp "${FIX}/lint/lint-issues.ts" lint/lint-issues.ts
  cp "${FIX}/lint/tsc-issue.ts" lint/tsc-issue.ts
  cp "${FIX}/lint/lint-issues.ts" utils/lint-issues.ts
  commit_push_wait "test: 隔离环境开启 lint 工具并加入 lint 夹具（FT-191/193/194/196/198）"
fi

if stage 2; then
  say "== 阶段 2：删除 eslint.config.js 与 tsconfig.json，验证无配置时安全降级"
  git rm -q eslint.config.js tsconfig.json
  mkdir -p noconfig
  cat > noconfig/no-config.ts <<'EOF'
export function divide(a: number, b: number): number {
  console.log("dividing", a, b);
  if (a == 0) {
    return 0;
  }
  return a / b;
}
EOF
  commit_push_wait "test: 删除 eslint 与 tsc 配置并新增文件，验证无配置降级（FT-192/195）"
fi

if stage 3; then
  say "== 阶段 3：恢复配置，显式开启 prettier，并加入格式不规范文件"
  git checkout -q "$(git rev-list -n 1 HEAD -- eslint.config.js | head -1)^" -- eslint.config.js tsconfig.json 2>/dev/null || {
    cp "${ORIG}/eslint.config.js" eslint.config.js
    printf '{\n  "compilerOptions": {\n    "target": "ES2022",\n    "module": "ESNext",\n    "moduleResolution": "Bundler",\n    "strict": true,\n    "noEmit": true,\n    "skipLibCheck": true\n  },\n  "include": ["**/*.ts"]\n}\n' > tsconfig.json
  }
  set_input enable_prettier true
  mkdir -p style
  cat > style/ugly.ts <<'EOF'
export   function   sum( a:number,b:number ){
return a+b
}
export const   obj={a:1,
   b:2}
EOF
  commit_push_wait "test: 恢复配置并显式开启 prettier，新增格式不规范文件（FT-197）"
fi

if stage 4; then
  say "== 阶段 4：显式开启 semgrep（默认规则）"
  set_input enable_semgrep true
  mkdir -p sec
  cat > sec/vuln.ts <<'EOF'
import {exec} from "child_process";

export function run(userInput: string) {
  exec("ls " + userInput);
  return eval(userInput);
}

export const apiKey = "AKIAIOSFODNN7EXAMPLE";
EOF
  commit_push_wait "test: 显式开启 semgrep 并新增有漏洞的文件（FT-199）"
fi

if stage 5; then
  say "== 阶段 5：semgrep_config 指向仓库内自定义规则"
  mkdir -p .semgrep sec
  cat > .semgrep/custom.yml <<'EOF'
rules:
  - id: ft200-custom-marker
    languages: [typescript]
    severity: WARNING
    message: FT200 custom rule matched (semgrep_config is effective)
    pattern: FT200_MARKER($X)
EOF
  cat > sec/custom-marker.ts <<'EOF'
declare function FT200_MARKER(x: unknown): void;
export function useMarker(v: string) {
  FT200_MARKER(v);
}
EOF
  set_input semgrep_config ".semgrep/custom.yml"
  commit_push_wait "test: semgrep_config 指向自定义规则并新增命中文件（FT-200）"
fi

if stage 6; then
  say "== 阶段 6：显式指定 eslint_version / prettier_version"
  set_input eslint_version '"9.17.0"'
  set_input prettier_version '"3.3.3"'
  mkdir -p version
  cat > version/version-probe.ts <<'EOF'
export function probe(list: string[]) {
  let unused = 1;
  console.log(list);
  return list.map((v) => v == "a");
}
EOF
  commit_push_wait "test: 显式指定 eslint/prettier 版本并新增文件（FT-201）"
fi

if stage 7; then
  say "== 阶段 7：eslint_version 设为不存在的版本，验证安装失败时安全降级"
  set_input eslint_version '"9.999.999"'
  mkdir -p install-fail
  cat > install-fail/probe.ts <<'EOF'
export function broken(items: string[]) {
  console.log(items);
  return items.filter((i) => i == "x").length;
}
EOF
  commit_push_wait "test: eslint_version 设为不存在的版本并新增文件（FT-202）"
fi

say "全部阶段完成。请告诉 Claude。（日志: ${LOG}）"
