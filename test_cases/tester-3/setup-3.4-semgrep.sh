#!/usr/bin/env bash
#
# setup-3.4-semgrep.sh — 准备 3.4.7 Semgrep SAST 扫描场景
#
# 验证项目:
#   3.4.7 Semgrep SAST 扫描 — 检出安全漏洞 + 引用 Semgrep 规则 ID
#
# 前置条件:
#   workflow 中已设置 enable_semgrep: true
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-3/setup-3.4-semgrep.sh
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
BRANCH="test/tester3-semgrep-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 3.4.7 Semgrep SAST 扫描"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""
echo "⚠️  请确认 workflow 中已设置 enable_semgrep: true"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

mkdir -p quality-tests

echo "==> 写入 quality-tests/security-semgrep.ts（Semgrep 可检测的安全问题）"
cat > quality-tests/security-semgrep.ts << 'EOF'
import express from 'express'
import { execSync } from 'child_process'
import * as path from 'path'
import * as fs from 'fs'

const app = express()
app.use(express.json())

// semgrep: javascript.express.security.audit.xss.mustache-escape
// 反射型 XSS — 用户输入直接嵌入 HTML
app.get('/profile', (req, res) => {
  const name = req.query.name
  res.send(`<h1>Welcome ${name}</h1><p>Your profile page</p>`)
})

// semgrep: javascript.lang.security.audit.dangerous-exec
// OS 命令注入 — 用户输入直接传入 execSync
app.post('/run', (req, res) => {
  const command = req.body.command
  const output = execSync(command)
  res.json({ output: output.toString() })
})

// semgrep: javascript.lang.security.audit.path-traversal
// 路径遍历 — 用户输入直接拼接文件路径
app.get('/file', (req, res) => {
  const filename = req.query.name as string
  const filePath = path.join('/uploads', filename)
  const content = fs.readFileSync(filePath, 'utf-8')
  res.send(content)
})

// semgrep: javascript.lang.security.audit.eval-injection
// eval 注入 — 用户输入直接 eval
app.post('/calc', (req, res) => {
  const expression = req.body.expr
  const result = eval(expression)
  res.json({ result })
})

app.listen(3000)
EOF

git add quality-tests/security-semgrep.ts
git commit -m "test: add Semgrep SAST test file (tester 3 — 3.4.7)

quality-tests/security-semgrep.ts:
  - XSS (反射型): 用户输入直接嵌入 HTML 响应
  - OS 命令注入: 用户输入直接传入 execSync
  - 路径遍历: 用户输入拼接文件路径
  - eval 注入: 用户输入直接 eval
  验证: Semgrep 检出安全漏洞 + 评论引用规则 ID"

git push -u origin "$BRANCH"

PR_URL=$(gh pr create \
  --title "[TEST 3.4.7] Semgrep SAST 安全漏洞扫描" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 AI Reviewer Semgrep SAST 集成 (3.4.7)。

## 前置条件

- workflow 中 `enable_semgrep: true`

## 代码改动

### `quality-tests/security-semgrep.ts` — 4 种 OWASP 安全漏洞

| 漏洞类型 | Semgrep 规则 | 代码位置 |
|---------|-------------|---------|
| 反射型 XSS | `javascript.express.security.audit.xss.mustache-escape` | `/profile` 路由 |
| OS 命令注入 | `javascript.lang.security.audit.dangerous-exec` | `/run` 路由 |
| 路径遍历 | `javascript.lang.security.audit.path-traversal` | `/file` 路由 |
| eval 注入 | `javascript.lang.security.audit.eval-injection` | `/calc` 路由 |

## 预期 Bot 行为

- [ ] 3.4.7: 行级评论中引用 Semgrep 规则 ID 或规则名称
- [ ] 评论中标注为 critical 级别（🚨）
- [ ] 至少检出 3/4 种漏洞

## 验证方式

1. 检查行级评论是否引用 Semgrep 规则
2. Actions 日志中搜索 `semgrep` 关键词
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (3.4.7): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 1~3 分钟后验证:"
echo "  ✓ 评论中引用 Semgrep 规则 ID"
echo "  ✓ 至少 3 种安全漏洞被检出"
echo "  ✓ 评论标注为 critical（🚨 严重）级别"
