#!/usr/bin/env bash
#
# setup-1.4-file-filters.sh — 准备 1.4 文件过滤与限制场景
#
# 验证项目:
#   1.4.1 二进制文件排除（.png 不审查）
#   1.4.2 path_filters 排除 .css 文件
#   1.4.4 lock 文件排除（pnpm-lock.yaml）
#
# 注意: 1.4.3（max_files 限制）需要临时修改 workflow 配置，单独处理
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-1/setup-1.4-file-filters.sh
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
BRANCH="test/tester1-filters-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 1.4 文件过滤与限制（1.4.1 / 1.4.2 / 1.4.4）"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"

# ---- 1.4.2: .css 文件（应被 path_filters 排除）----
echo "==> 创建 assets/ignored.css（应被排除）"
mkdir -p assets
cat > assets/ignored.css << 'EOF'
/* 这个 CSS 文件不在 path_filters 范围内，Bot 不应审查 */
.button {
  color: red
  background: blue;  /* 故意缺少分号，但 Bot 不应注意到 */
}
EOF

# ---- 1.4.4: 模拟 lock 文件变化 ----
echo "==> 创建 pnpm-lock.yaml 变更（应被排除）"
# 只追加一条注释，不破坏真实 lock 格式
if [[ -f "pnpm-lock.yaml" ]]; then
  # 在末尾追加注释行触发 diff
  echo "" >> pnpm-lock.yaml
  echo "# test: tester-1 filter test marker $(date +%s)" >> pnpm-lock.yaml
else
  cat > pnpm-lock.yaml << 'EOF'
lockfileVersion: '9.0'

# test: tester-1 filter test marker
settings:
  autoInstallPeers: true
  excludeLinksFromLockfile: false
EOF
fi

# ---- 1.4.1: 二进制文件（.png）----
echo "==> 创建二进制 PNG 文件 assets/test-icon.png（应被排除）"
mkdir -p assets
# 生成最小合法 PNG（8x8 透明）
python3 -c "
import base64, sys
# 最小 1x1 透明 PNG (base64)
data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
sys.stdout.buffer.write(base64.b64decode(data))
" > assets/test-icon.png

# ---- 真正需要审查的代码变更 ----
echo "==> 创建 utils/filter-test.ts（应被审查）"
cat > utils/filter-test.ts << 'EOF'
// utils/filter-test.ts
// 这是唯一应该被审查的文件（.ts 在 path_filters 范围内）

export function processUserData(data: any) {
  // 问题: 直接使用 any 类型
  // 问题: 未做输入校验
  return JSON.parse(data)
}

export function buildUrl(base: string, path: string) {
  // 问题: 字符串拼接而非 URL 构造器
  return base + '/' + path
}
EOF

git add utils/filter-test.ts assets/ignored.css assets/test-icon.png pnpm-lock.yaml
git commit -m "test: file filter validation (1.4.1 / 1.4.2 / 1.4.4)

变更文件:
- utils/filter-test.ts     [.ts, 应审查]
- assets/ignored.css       [.css, 应被 path_filters 排除]
- assets/test-icon.png     [二进制, 应被排除]
- pnpm-lock.yaml           [*.lock, 应被排除]"

git push -u origin "$BRANCH"

PR_URL=$(gh pr create \
  --title "[TEST 1.4] 文件过滤验证：二进制 / CSS / lock 排除" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 AI Reviewer 文件过滤机制（用例 1.4.1 / 1.4.2 / 1.4.4）。

## 变更文件

| 文件 | 类型 | 预期 |
|------|------|------|
| `utils/filter-test.ts` | `.ts` | ✅ 应被审查 |
| `assets/ignored.css` | `.css` | ❌ path_filters 排除 |
| `assets/test-icon.png` | 二进制 | ❌ 二进制排除 |
| `pnpm-lock.yaml` | lock 文件 | ❌ `*.lock` 模式排除 |

## 预期 Bot 行为

- 只对 `utils/filter-test.ts` 产出评论
- 不对 CSS / PNG / lock 文件产出任何评论
- Actions 日志中应有跳过文件的记录

## 验证清单

- [ ] 1.4.1: Bot 评论中无 PNG 文件相关内容
- [ ] 1.4.2: Bot 评论中无 CSS 文件相关内容
- [ ] 1.4.4: Bot 评论中无 lock 文件相关内容
- [ ] filter-test.ts 被正常审查
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (1.4.1 / 1.4.2 / 1.4.4): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 Bot 审查完成后，检查 PR 评论中只涉及 filter-test.ts。"
echo ""
echo "1.4.3（max_files 限制）需临时修改 workflow，独立验证:"
echo "  bash test_cases/tester-1/setup-1.4-max-files.sh"
