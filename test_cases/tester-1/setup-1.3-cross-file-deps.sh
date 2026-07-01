#!/usr/bin/env bash
#
# setup-1.3-cross-file-deps.sh — 准备 1.3 跨文件依赖分析场景
#
# 验证项目:
#   1.3.1 修改导出函数签名 → 审查评论提及引用方文件
#   1.3.2 TypeScript named import 解析
#   1.3.3 Vue composable auto-import 检测（useCart）
#
# 设计思路:
#   利用仓库现有文件作为引用方（不在 PR 中修改）:
#     - components/ProductCard.vue  → 显式 import formatPrice
#     - components/CartSummary.vue  → auto-import useCart (Nuxt)
#     - pages/cart.vue              → auto-import useCart (Nuxt)
#   PR 中只改 utils/formatPrice.ts + composables/useCart.ts
#   Bot 应通过依赖分析感知到这些引用方受影响
#
# 用法:
#   cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
#   GITHUB_TOKEN=<token> bash test_cases/tester-1/setup-1.3-cross-file-deps.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  SECRETS_FILE="$REPO_ROOT/.secrets"
  if [[ -f "$SECRETS_FILE" ]]; then
    export GITHUB_TOKEN="$(grep '^GITHUB_TOKEN=' "$SECRETS_FILE" | sed 's/^GITHUB_TOKEN=//' | tr -d '[:space:]')"
  fi
fi
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "❌ GITHUB_TOKEN 未设置，请在 .secrets 文件中配置或通过环境变量传入" >&2
  exit 1
fi
export GH_TOKEN="$GITHUB_TOKEN"

BASE_BRANCH="test/dev4"
BRANCH="test/tester1-cross-file-$(date +%m%d-%H%M)"

echo "================================================================"
echo "  场景: 1.3 跨文件依赖分析"
echo "  分支: ${BRANCH} → ${BASE_BRANCH}"
echo "================================================================"
echo ""
echo "引用方（已存在，PR 中不修改）:"
echo "  - components/ProductCard.vue  [显式 import formatPrice]"
echo "  - components/CartSummary.vue  [auto-import useCart]"
echo "  - pages/cart.vue              [auto-import useCart]"
echo ""

git fetch origin "$BASE_BRANCH" --quiet
git checkout -b "$BRANCH" "origin/$BASE_BRANCH"
git branch --unset-upstream

# ---- 变更 1: formatPrice 签名破坏性改动 ----
echo "==> 修改 utils/formatPrice.ts（签名破坏性变更）"
printf '// generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" > utils/formatPrice.ts
cat >> utils/formatPrice.ts << 'EOF'
/**
 * 价格格式化工具
 *
 * Breaking change:
 *   - currency 变为必需参数（移除默认值）
 *   - 参数顺序改为 (amount, locale, currency)
 *   - 新增负数保护
 *
 * 受影响引用方:
 *   - components/ProductCard.vue: formatPrice(props.price) 调用缺少新必需参数
 *   - 其他调用 formatPrice 且未传 locale/currency 的地方
 */
export function formatPrice(
  amount: number,
  locale: string,       // 新增: 展示区域（原无此参数）
  currency: string      // 改动: 移除默认值 "USD"，变为必需参数
): string {
  if (amount < 0) return 'N/A'
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency
  }).format(amount)
}
EOF

# ---- 变更 2: useCart 返回类型变更 ----
echo "==> 修改 composables/useCart.ts（返回类型破坏性变更）"
printf '// generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" > composables/useCart.ts
cat >> composables/useCart.ts << 'EOF'
/**
 * 购物车 composable
 *
 * Breaking change:
 *   - removeItem 新增必需参数 reason: string
 *   - total 从 computed<number> 改为 computed<{ amount: number; tax: number }>
 *
 * 受影响引用方:
 *   - components/CartSummary.vue: 使用 total（类型变化）
 *   - pages/cart.vue: 使用 removeItem（缺少 reason 参数）
 */
export interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
}

export function useCart() {
  const items = useState<CartItem[]>('cart-items', () => [])

  // 类型从 number 变为对象
  const total = computed(() => {
    const amount = items.value.reduce((sum, item) => sum + item.price * item.quantity, 0)
    return { amount, tax: amount * 0.1 }
  })

  function addItem(item: Omit<CartItem, 'quantity'>) {
    const existing = items.value.find((i) => i.id === item.id)
    if (existing) {
      existing.quantity++
    } else {
      items.value.push({ ...item, quantity: 1 })
    }
  }

  // 新增必需参数 reason
  function removeItem(id: string, reason: string) {
    console.log(`Removing item ${id}: ${reason}`)
    items.value = items.value.filter((i) => i.id !== id)
  }

  return { items, total, addItem, removeItem }
}
EOF

git add utils/formatPrice.ts composables/useCart.ts
git commit -m "feat: breaking changes to formatPrice + useCart (1.3 跨文件依赖分析测试)

utils/formatPrice.ts:
  - currency 从可选变为必需参数
  - 新增 locale 参数（改变参数顺序）
  - 新增负数保护

composables/useCart.ts:
  - total 返回类型从 number → { amount, tax }
  - removeItem 新增必需参数 reason: string

引用方（未修改，期望 Bot 依赖分析感知）:
  - components/ProductCard.vue（显式 import formatPrice）
  - components/CartSummary.vue（auto-import useCart）
  - pages/cart.vue（auto-import useCart）"

git push origin "${BRANCH}:${BRANCH}"

PR_URL=$(gh pr create \
  --title "[TEST 1.3] 跨文件依赖分析：破坏性签名变更" \
  --base "$BASE_BRANCH" \
  --body "$(cat << 'BODY'
## 目的

验证 AI Reviewer 跨文件依赖分析（用例 1.3.1 ~ 1.3.3）。

## 代码改动

### `utils/formatPrice.ts`（Breaking Change）
- `currency` 从可选 `= "USD"` 变为**必需参数**
- 新增 `locale: string` 参数（参数顺序变化）
- 新增负数输入保护

### `composables/useCart.ts`（Breaking Change）
- `total` 返回类型从 `number` 变为 `{ amount: number; tax: number }`
- `removeItem` 新增必需参数 `reason: string`

## 未修改的引用方（期望依赖分析感知）

| 文件 | 引用方式 | 受影响原因 |
|------|---------|-----------|
| `components/ProductCard.vue` | 显式 `import { formatPrice }` | 调用时缺少新必需参数 |
| `components/CartSummary.vue` | Nuxt auto-import `useCart` | `total.value` 类型变化 |
| `pages/cart.vue` | Nuxt auto-import `useCart` | `removeItem` 缺少 reason 参数 |

## 预期 Bot 行为

1. **1.3.1** — 审查评论中提及 `ProductCard.vue` 作为 `formatPrice` 的引用方
2. **1.3.2** — 识别 TypeScript named import（`import { formatPrice } from '~/utils/formatPrice'`）
3. **1.3.3** — 通过 auto-import 检测到 `CartSummary.vue` / `cart.vue` 使用 `useCart`

## 验证清单

- [ ] 1.3.1: 评论或摘要中出现 `ProductCard.vue` 文件名
- [ ] 1.3.2: Bot 识别到 formatPrice 的 TS 显式引用方
- [ ] 1.3.3: Bot 识别到 useCart 的 Nuxt auto-import 引用方（CartSummary.vue / cart.vue）
BODY
)")

echo ""
echo "================================================================"
echo "  ✅ PR 已创建 (1.3.1 ~ 1.3.3): ${PR_URL}"
echo "================================================================"
echo ""
echo "等待 1~3 分钟后检查:"
echo "  ✓ 摘要/评论中是否提及 ProductCard.vue（显式引用，1.3.1 / 1.3.2）"
echo "  ✓ 摘要/评论中是否提及 CartSummary.vue 或 cart.vue（auto-import，1.3.3）"
