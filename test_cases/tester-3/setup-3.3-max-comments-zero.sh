#!/usr/bin/env bash
#
# setup-3.3-max-comments-zero.sh — 准备 3.3.6 不截断（max_review_comments=0）场景
#
# 验证项目:
#   3.3.6 max_review_comments: 0 → 所有评论都展示，无截断提示
#
# 前置条件:
#   ⚠️ 需要先手动修改 .github/workflows/ai-reviewer.yml 中的配置:
#      max_review_comments: 0
#   测试完成后记得恢复原值!
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-3/setup-3.3-max-comments-zero.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  SECRETS_FILE="$REPO_ROOT/.secrets"
  if [[ -f "$SECRETS_FILE" ]]; then
    export GITHUB_TOKEN="$(grep '^GITHUB_TOKEN=' "$SECRETS_FILE" | cut -d= -f2)"
  fi
fi
export GH_TOKEN="$GITHUB_TOKEN"

BASE_BRANCH="test/dev4"
BRANCH="test/tester3-maxzero-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 3.3.6 不截断（max_review_comments=0）"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚠️  前置操作: 修改 .github/workflows/ai-reviewer.yml"
echo "     设置 max_review_comments: 0"
echo "     测试完成后恢复原值!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "已确认修改 workflow 配置? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "请先修改 .github/workflows/ai-reviewer.yml 中的 max_review_comments: 0"
  exit 1
fi

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

mkdir -p quality-tests

# 写入大量问题代码，确保超过默认截断数
echo "==> 写入 quality-tests/many-issues.ts（大量问题，验证不截断）"
cat > quality-tests/many-issues.ts << 'EOF'
import { readFileSync } from 'fs'

// 25+ 个不同问题，验证 max_review_comments=0 时全部展示

export function issue1(input: string) { eval(input) }
export function issue2(input: string) { return `SELECT * FROM t WHERE id='${input}'` }
export function issue3(input: string) { document.innerHTML = input }
export function issue4(cmd: string) { require('child_process').execSync(cmd) }
export function issue5() { return Math.random().toString(36) }

export async function issue6(url: string) { fetch(url) }
export function issue7(a: number, b: number) { return a / b }
export function issue8(json: string) { return JSON.parse(json) }
export function issue9() { var x = 1; return x }
export function issue10() { var y = 2; return y }

export function issue11() { let z = 'const'; return z }
export function issue12() { let w = 'const2'; return w }
export function issue13(a: any) { return a }
export function issue14(b: any) { return b.x.y.z }
export function issue15() { console.log('debug') }

export function issue16() { console.log('debug2') }
export function issue17(x: number) { return x == 0 }
export function issue18(x: number) { return x == 1 }
export function issue19() { const fs = readFileSync; return 'unused' }
export function issue20() { return new Date().getTime() }

export function issue21() { return {} as any }
export function issue22(input: string) { return eval(`(${input})`) }
export function issue23() { return Math.random() * 100 }
export function issue24() { return Math.random() * 200 }
export function issue25() { return Math.random() * 300 }
export function issue26() { return Math.random() * 400 }
EOF

git add quality-tests/many-issues.ts
git commit -m "test: add 26 issues for max_review_comments=0 test (tester 3 — 3.3.6)

验证 max_review_comments=0 时不截断，所有评论展示。
包含 26 个不同严重级别的问题。"

git push -u origin "$BRANCH"

PR_URL=$(gh pr create \
  --title "[TEST 3.3.6] max_review_comments=0 不截断验证" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 `max_review_comments: 0` 时 Bot 不截断评论（用例 3.3.6）。

## 前置条件

- ⚠️ workflow 已设置 `max_review_comments: 0`

## 代码改动

### `quality-tests/many-issues.ts` — 26 个刻意问题
- 4 critical（eval/SQL注入/XSS/命令注入）
- 3 major（未await/除零/未try-catch）
- 多个 minor/nit（var/let/console.log/unused等）
- 合计 26 个问题（超过默认限制 20）

## 预期 Bot 行为

- [ ] 3.3.6: 所有评论都展示，无 "N 条评论已省略" 提示
- [ ] 评论数 > 20（证明未被截断）
- [ ] 摘要中无截断相关文字

## 测试完成后

⚠️ 恢复 `.github/workflows/ai-reviewer.yml` 中 `max_review_comments` 为原值!
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (3.3.6): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 Bot 完成后验证:"
echo "  ✓ 评论总数 > 20（未被截断）"
echo "  ✓ 摘要中无 \"已省略\" 提示"
echo ""
echo "⚠️  测试完成后记得恢复 max_review_comments 配置!"
