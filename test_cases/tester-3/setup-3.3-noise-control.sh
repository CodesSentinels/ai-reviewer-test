#!/usr/bin/env bash
#
# setup-3.3-noise-control.sh — 准备 3.3 噪音控制 + 3.4 Lint 集成 + 3.5 去重场景
#
# 验证项目:
#   3.3.1 严重级别徽标（emoji + 中文标签）
#   3.3.2 级别排序（critical > major > minor > nit）
#   3.3.3 评论数量截断（≤ max_review_comments=20）
#   3.3.4 截断保留高优先级（critical/major 不被丢弃）
#   3.3.5 同类评论合并（Math.random 重复模式）
#   3.4.1 ESLint 检测结果注入（no-unused-vars / no-undef）
#   3.4.2 tsc 类型错误（TS2345）
#   3.4.3 Biome 检测（noExplicitAny / useConst）
#   3.4.4 工具归因卡片（🧰 Tools 段落）
#   3.5.1 同 lint finding 合并（连续 var 声明）
#   3.5.2 不同 lint finding 不合并
#   3.5.3 合并后行号范围扩展
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-3/setup-3.3-noise-control.sh
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
BRANCH="test/tester3-noise-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 3.3 噪音控制 + 3.4 Lint + 3.5 去重"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

mkdir -p quality-tests

# ---- 文件 1: quality-issues.ts — 混合各级别问题（3.3.1~3.3.5）----
echo "==> 写入 quality-tests/quality-issues.ts（混合级别问题）"
cat > quality-tests/quality-issues.ts << 'EOF'
import { readFileSync } from 'fs'

// ===== Critical 问题（期望 🚨 严重）=====
export function login(username: string, password: string) {
  const query = `SELECT * FROM users WHERE name='${username}' AND pwd='${password}'`
  eval(query)
}

export function renderHtml(userInput: string) {
  document.innerHTML = userInput
}

export function executeCommand(cmd: string) {
  require('child_process').execSync(cmd)
}

// ===== Major 问题（期望 ⚠️ 主要）=====
export async function fetchData(url: string) {
  fetch(url)
}

export function divide(a: number, b: number) {
  return a / b
}

export function parseConfig(json: string) {
  return JSON.parse(json)
}

// ===== Minor / Nit 问题（期望 📝 建议 / 💡 微调）=====
export function formatName(first: string, last: string) {
  var fullName = first + ' ' + last
  return fullName
}

// 同类模式重复 5 次 — 期望合并为 1~2 条评论（3.3.5）
export function getRandomId() { return Math.random().toString(36).slice(2) }
export function getRandomToken() { return Math.random().toString(36).slice(2) }
export function getRandomKey() { return Math.random().toString(36).slice(2) }
export function getRandomValue() { return Math.random().toString(36).slice(2) }
export function getRandomHash() { return Math.random().toString(36).slice(2) }

export function unusedImportDemo() {
  const fs = readFileSync
  return 'hello'
}
EOF

# ---- 文件 2: lint-violations.ts — 触发多种 lint 工具（3.4.1~3.4.3）----
echo "==> 写入 quality-tests/lint-violations.ts（lint 工具检测）"
cat > quality-tests/lint-violations.ts << 'EOF'
import { readFileSync } from 'fs'

// ESLint: no-unused-vars（3.4.1）
const unusedVariable = 42

// ESLint: no-undef / tsc: TS2304（3.4.1 / 3.4.2）
function callUndefined() {
  return undeclaredFunction()
}

// tsc: TS2345 类型不匹配（3.4.2）
function expectNumber(n: number): number {
  return n * 2
}
const result = expectNumber("hello" as any as number)

// Biome: noExplicitAny（3.4.3）
export function unsafeAny(x: any): any {
  return x.foo.bar.baz
}

// Biome: useConst（3.4.3）
export function shouldUseConst() {
  let value = 'never reassigned'
  return value
}
EOF

# ---- 文件 3: dedup-scenarios.ts — 触发评论去重（3.5.1~3.5.3）----
echo "==> 写入 quality-tests/dedup-scenarios.ts（去重验证）"
cat > quality-tests/dedup-scenarios.ts << 'EOF'
export function processItems(items: string[]) {
  // 连续 5 行相同模式违规 → 应合并为一条（3.5.1 / 3.5.3）
  var item1 = items[0]
  var item2 = items[1]
  var item3 = items[2]
  var item4 = items[3]
  var item5 = items[4]

  // 不同类型违规 → 不应合并（3.5.2）
  eval(item1)
  console.log(item2)
  return item3 == item4 ? item5 : null
}
EOF

# ---- 文件 4: conversation-anchor.ts — 追问锚点（供 3.1 对话测试使用）----
echo "==> 写入 quality-tests/conversation-anchor.ts（对话追问锚点）"
cat > quality-tests/conversation-anchor.ts << 'EOF'
export function processPayment(amount: number, userId: string) {
  if (amount) {
    const query = `UPDATE balance SET amount = ${amount} WHERE user = '${userId}'`
    return executeQuery(query)
  }
}

export function generateToken(): string {
  return Math.random().toString(36).slice(2)
}
EOF

git add quality-tests/
git commit -m "test: add quality control test files (tester 3 — 3.3/3.4/3.5)

quality-tests/quality-issues.ts:
  - 3 critical（SQL注入/XSS/命令注入）
  - 3 major（未await/除零/未try-catch）
  - 5 重复 Math.random + 1 unused import
  验证: 级别徽标、排序、截断、同类合并

quality-tests/lint-violations.ts:
  - ESLint: unused-vars / no-undef
  - tsc: TS2345 类型不匹配
  - Biome: noExplicitAny / useConst
  验证: lint 结果注入、工具归因卡片

quality-tests/dedup-scenarios.ts:
  - 连续 5 行 var 声明（同类合并）
  - eval + console.log + ==（不同类不合并）

quality-tests/conversation-anchor.ts:
  - SQL 注入 + Math.random token
  验证: 作为 3.1 对话追问的锚点"

git push origin "HEAD:refs/heads/$BRANCH" --set-upstream

# 记录分支名供后续脚本复用
echo "$BRANCH" > /tmp/tester3-noise-branch

PR_URL=$(gh pr create \
  --title "[TEST 3.3/3.4/3.5] 噪音控制 + Lint 集成 + 评论去重" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 AI Reviewer 噪音控制 (3.3)、Linter/SAST 集成 (3.4)、AI 评论去重 (3.5) 功能。

## 代码改动

### `quality-tests/quality-issues.ts` — 混合级别问题
| 问题类型 | 数量 | 期望级别 |
|---------|------|---------|
| SQL 注入 / XSS / 命令注入 | 3 | 🚨 critical |
| 未 await / 除零 / 未 try-catch | 3 | ⚠️ major |
| var 声明 / unused import | 2 | 📝 minor |
| Math.random 重复×5 | 5（期望合并为 1~2 条） | 💡 nit |

### `quality-tests/lint-violations.ts` — Lint 工具检测
- ESLint: `no-unused-vars`, `no-undef`
- tsc: `TS2345` 类型不匹配
- Biome: `noExplicitAny`, `useConst`

### `quality-tests/dedup-scenarios.ts` — 评论去重
- 5 行连续 `var` → 应合并为 1 条
- `eval` + `console.log` + `==` → 各自独立评论

### `quality-tests/conversation-anchor.ts` — 对话追问锚点
- SQL 注入 + Math.random（供后续 3.1 追问测试使用）

## 预期 Bot 行为

### 3.3 噪音控制
- [ ] 3.3.1: 行级评论顶部有 `🚨 严重` / `⚠️ 主要` / `📝 建议` / `💡 微调` 标签
- [ ] 3.3.2: critical 评论排在 major 之前，major 排在 minor/nit 之前
- [ ] 3.3.3: 最终评论总数 ≤ 20
- [ ] 3.3.4: 3 条 critical 全部保留，被截断的是低优先级
- [ ] 3.3.5: 5 个 Math.random 函数合并为 1~2 条评论

### 3.4 Lint 集成
- [ ] 3.4.1: 评论中出现 ESLint 规则名（如 `no-unused-vars`）
- [ ] 3.4.2: 评论中引用 TypeScript 错误码（如 `TS2345`）
- [ ] 3.4.3: 评论中引用 Biome 规则（如 `noExplicitAny`）
- [ ] 3.4.4: 行级评论底部有 `🧰 Tools` 段落

### 3.5 评论去重
- [ ] 3.5.1: 5 行 `var` 声明合并为 1 条评论
- [ ] 3.5.2: `eval` / `console.log` / `==` 各自独立评论
- [ ] 3.5.3: 合并后的评论行号范围覆盖第 1 到第 5 个 var 行

## 后续步骤

Bot 产出行级评论后，使用 `test-3.1-conversation.sh` 进行对话追问测试。
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (3.3/3.4/3.5): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 1~3 分钟后验证:"
echo "  ✓ 3.3.1: 评论有严重级别 emoji 标签"
echo "  ✓ 3.3.2: critical 排在前面"
echo "  ✓ 3.3.3: 总评论数 ≤ 20"
echo "  ✓ 3.3.5: Math.random 重复被合并"
echo "  ✓ 3.4.1~3.4.4: lint 规则引用 + Tools 卡片"
echo "  ✓ 3.5.1~3.5.3: var 声明合并为一条评论"
echo ""
echo "----------------------------------------------------------------"
echo "  Bot 产出评论后，运行对话追问测试:"
echo "  bash test_cases/tester-3/test-3.1-conversation.sh"
echo "----------------------------------------------------------------"
