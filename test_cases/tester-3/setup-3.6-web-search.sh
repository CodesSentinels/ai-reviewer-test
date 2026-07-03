#!/usr/bin/env bash
#
# setup-3.6-web-search.sh — 准备 3.6 Web 搜索与 Shell 执行场景
#
# 验证项目:
#   3.6.1 Web 搜索验证 API 用法（Analysis chain 含 web_search）
#   3.6.2 Shell 执行辅助分析（Analysis chain 含 shell 步骤）
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-3/setup-3.6-web-search.sh
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
BRANCH="test/tester3-websearch-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 3.6 Web 搜索与 Shell 执行"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

mkdir -p quality-tests

# ---- 文件 1: web-search-trigger.ts — 使用冷门/新 API 触发联网搜索（3.6.1）----
echo "==> 写入 quality-tests/web-search-trigger.ts（触发联网搜索）"
cat > quality-tests/web-search-trigger.ts << 'EOF'
import { experimental_useOptimistic } from 'react'

/**
 * 使用最新/实验性 API，期望触发 Bot 的 web_search 工具
 */
export function PaymentForm() {
  const [optimistic, setOptimistic] = experimental_useOptimistic(null)

  // Web Crypto API 的较新方法 — PBKDF2 密钥派生
  async function deriveKey(password: string) {
    const encoder = new TextEncoder()
    const salt = crypto.getRandomValues(new Uint8Array(16))

    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      encoder.encode(password),
      'PBKDF2',
      false,
      ['deriveKey']
    )

    return crypto.subtle.deriveKey(
      { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt', 'decrypt']
    )
  }

  return { optimistic, deriveKey }
}

// 使用 Node.js 22+ 的新 API
import { styleText } from 'node:util'

export function colorLog(msg: string) {
  console.log(styleText('red', msg))
}
EOF

# ---- 文件 2: shell-trigger.ts — 依赖版本相关问题触发 shell 执行（3.6.2）----
echo "==> 写入 quality-tests/shell-trigger.ts（触发 shell 执行）"
cat > quality-tests/shell-trigger.ts << 'EOF'
/**
 * 使用特定版本依赖 API — 期望触发 Bot 的 shell 工具
 * （如 npm info / cat package.json 检查版本兼容性）
 */
import Fastify from 'fastify'

const app = Fastify({ logger: true })

// Fastify v5 breaking change: 路由选项语法变更
app.get('/api/users', {
  schema: {
    response: {
      200: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            name: { type: 'string' }
          }
        }
      }
    }
  }
}, async (request, reply) => {
  // 使用 reply.code() 替代 reply.status()（v5 变更）
  return reply.code(200).send([{ id: 1, name: 'Alice' }])
})

// 使用 deprecated 的 decorateRequest 语法
app.decorateRequest('user', null)

app.listen({ port: 3000 })
EOF

git add quality-tests/
git commit -m "test: add web search + shell trigger files (tester 3 — 3.6)

quality-tests/web-search-trigger.ts:
  - experimental_useOptimistic (React 实验性 API)
  - Web Crypto PBKDF2 密钥派生
  - Node.js 22 styleText API
  验证: Bot 触发 web_search 检索 API 文档

quality-tests/shell-trigger.ts:
  - Fastify v5 破坏性变更
  - deprecated decorateRequest 用法
  验证: Bot 触发 shell 检查 package.json / npm info"

git push -u origin "$BRANCH"

PR_URL=$(gh pr create \
  --title "[TEST 3.6] Web 搜索 + Shell 执行验证" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 AI Reviewer 的 Web 搜索 (3.6.1) 和 Shell 执行 (3.6.2) 工具调用能力。

## 代码改动

### `quality-tests/web-search-trigger.ts`
- React `experimental_useOptimistic` — 实验性 API，需联网确认用法
- Web Crypto `PBKDF2` 密钥派生 — 较新的参数组合
- Node.js 22 `styleText` — 非常新的 API

### `quality-tests/shell-trigger.ts`
- Fastify v5 语法变更 — 需检查当前版本
- `decorateRequest` deprecated 用法 — 需检查 package.json 版本

## 预期 Bot 行为

- [ ] 3.6.1: 摘要或评论中引用搜索结果（如 API 文档链接或用法说明）
- [ ] 3.6.2: Actions 日志中有 shell 调用记录（如 `npm info` / `cat package.json`）

## 验证方式

1. 查看 Actions 日志: PR → Checks → Code Review → 展开步骤
2. 搜索关键词: `[web_search_debug]` / `[shell_debug]`
3. 查看评论中是否有 API 文档引用或版本信息
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (3.6): ${PR_URL}"
echo "================================================================"
echo ""
echo "验证方式:"
echo "  1. 打开 PR → Checks → Code Review → 展开日志"
echo "  2. 搜索 [web_search_debug] 确认 web search 触发（3.6.1）"
echo "  3. 搜索 [shell_debug] 确认 shell 执行触发（3.6.2）"
echo "  4. 查看评论中是否引用了 API 文档或版本信息"
