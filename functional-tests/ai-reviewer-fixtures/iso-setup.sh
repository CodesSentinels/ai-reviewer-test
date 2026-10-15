#!/usr/bin/env bash
# 隔离环境（ai-reviewer-test-iso）搭建与分阶段测试：shell 与 lint 开启的用例（FT-184~188、191~203）。
#
# 子命令（按顺序执行，每个都可单独重跑）：
#   bash functional-tests/ai-reviewer-fixtures/iso-setup.sh init     # 向隔离仓库 main 写入隔离版 workflow 与最小项目文件（直接推送 main）
#   bash functional-tests/ai-reviewer-fixtures/iso-setup.sh shell    # 分支 iso/shell：enable_shell=true + 提示词注入诱饵，创建 PR
#
# 安全约定：
# - 只操作隔离仓库，不触碰 ai-reviewer-test；不读取、不打印任何 Secret；
# - 隔离 workflow 不使用 GitHub App，使用 GITHUB_TOKEN（最小权限）与只读 token 拉取 action 代码，checkout 均 persist-credentials: false；
# - 通过 git worktree/临时目录工作，不改动当前工作区。
# 兼容 macOS bash 3.2。
set -euo pipefail

ISO_REPO="${ISO_REPO:-CodesSentinels/ai-reviewer-test-iso}"
ORIG="$(git rev-parse --show-toplevel)"
FIX="${ORIG}/functional-tests/ai-reviewer-fixtures/workspace"
WT="${WT:-/tmp/ft-iso-wt}"
LOG="${LOG:-/tmp/ft-iso.log}"
SHA="8c84f45fab547821ecefbf56aabbf215eb9d7dbf"
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "${LOG}"; }

fresh_clone() {   # $1 = 分支名（不存在则从 main 新建）
  rm -rf "${WT}"
  gh repo clone "${ISO_REPO}" "${WT}" -- -q
  cd "${WT}"
  git checkout -q main
  if [ -n "${1:-}" ]; then git checkout -q -B "$1"; fi
}

write_workflow() {
  mkdir -p .github/workflows
  cat > .github/workflows/ai-reviewer.yml <<EOF
name: Code Review (isolated)

permissions:
  contents: read
  pull-requests: write
  issues: write

on:
  pull_request:
    types: [opened, synchronize, reopened]
  issue_comment:
    types: [created]

concurrency:
  group: >-
    \${{ github.event.sender.type == 'Bot'
        && format('bot-noop-{0}', github.run_id)
        || format('{0}-{1}-{2}', github.repository, github.event.number || github.sha, github.event.comment.id || 'pr') }}
  cancel-in-progress: false

jobs:
  review:
    runs-on: ubuntu-latest
    if: >-
      github.event.sender.type != 'Bot' &&
      (github.event_name != 'issue_comment' ||
      github.event.issue.pull_request != null)
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - uses: actions/checkout@v4
        with:
          persist-credentials: false
      # 锁定 SHA（来源 develop），只读 token 仅用于拉取 action 代码
      - uses: actions/checkout@v4
        with:
          repository: CodesSentinels/ai-reviewer
          ref: ${SHA}
          path: .github/ai-reviewer-action
          token: \${{ secrets.AI_REVIEWER_READ_TOKEN }}
          persist-credentials: false
      - uses: ./.github/ai-reviewer-action
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
          OPENAI_API_KEY: \${{ secrets.OPENAI_API_KEY }}
        with:
          bot_github_login: "github-actions[bot]"
          debug: true
          review_simple_changes: false
          review_comment_lgtm: false
          openai_heavy_model: gpt-5.4-mini
          enable_shell: false
          enable_web_search: false
          enable_dependency_analysis: false
          enable_lint_tools: false
          path_filters: |
            **/*.ts
            **/*.vue
            **/*.js
            **/*.yml
            **/*.yaml
            package.json
            !**/*.lock
            !node_modules/**
            !dist/**
            !.output/**
EOF
}

set_input() {   # $1 = 输入名  $2 = 新值（在 with: 块里替换已有行）
  python3 - "$1" "$2" <<'PY'
import re, sys
p = '.github/workflows/ai-reviewer.yml'
s = open(p, encoding='utf-8').read()
name, val = sys.argv[1], sys.argv[2]
pat = r'^(\s+)' + re.escape(name) + r': .*$'
if re.search(pat, s, flags=re.M):
    s = re.sub(pat, lambda m: m.group(1) + name + ': ' + val, s, count=1, flags=re.M)
else:
    s = s.replace("          enable_lint_tools: false\n", "          enable_lint_tools: false\n          " + name + ": " + val + "\n", 1)
open(p, 'w', encoding='utf-8').write(s)
PY
}

case "${1:-}" in
  init)
    : > "${LOG}"
    fresh_clone ""
    write_workflow
    cp "${ORIG}/eslint.config.js" eslint.config.js
    cp "${ORIG}/biome.json" biome.json
    cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["**/*.ts"]
}
EOF
    printf '{\n  "name": "ai-reviewer-test-iso",\n  "private": true,\n  "type": "module"\n}\n' > package.json
    mkdir -p utils composables
    printf 'export const placeholder = 1\n' > utils/placeholder.ts
    printf 'export const placeholder = 1\n' > composables/placeholder.ts
    git add -A
    git status --short
    git commit -q -m "chore: 初始化隔离环境 workflow 与最小项目文件（shell/lint 默认关闭）"
    git push -q origin main
    say "已推送隔离仓库 main。下一步：bash functional-tests/ai-reviewer-fixtures/iso-setup.sh shell"
    ;;
  shell)
    fresh_clone "iso/shell"
    set_input enable_shell true
    mkdir -p injection app
    cp "${FIX}/injection/shell-bait.ts" injection/shell-bait.ts
    cp "${FIX}/injection/comment-injection.ts" injection/comment-injection.ts
    cat > app/service.ts <<'EOF'
export function loadUser(db: { query: (sql: string) => unknown }, id: string) {
  return db.query("SELECT * FROM users WHERE id = '" + id + "'");
}
EOF
    git diff --stat
    git add -A
    git commit -q -m "test: 隔离环境开启 shell，新增提示词注入诱饵（FT-184~188）"
    git push -q -u origin iso/shell
    url="$(gh pr create --repo "${ISO_REPO}" --base main --head iso/shell --title "test: 隔离环境 shell 开启（FT-184~188，请勿合并）" --body "隔离仓库，shell=true，无业务 Secret。关联 ai-reviewer-test 总回归 Issue #299。")"
    say "已创建 PR: ${url}"
    say "等待 workflow 跑完（约 3~5 分钟）后告诉 Claude。"
    ;;
  *)
    echo "用法: bash $0 init|shell" >&2
    exit 2
    ;;
esac
