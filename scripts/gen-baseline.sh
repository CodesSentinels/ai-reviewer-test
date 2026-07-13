#!/usr/bin/env bash
#
# gen-baseline.sh — 生成 CodeSentinel AI Reviewer 的「基准项目」代码
# =============================================================================
#
# 目的：
#   生成一个干净、可编译、无明显缺陷的 Nuxt/Vue + TypeScript 全栈项目，
#   作为后续所有测试的 **基线（before 状态）**。你把它提交到测试仓库的
#   基准分支（如 main / test/dev4）后，测试点脚本 gen-testpoints.sh 生成的
#   变更就能在这份基线之上产生真实的 diff、跨文件引用与增量审查场景。
#
# 设计原则：
#   1. 基线本身应尽量「干净」——不刻意埋 bug，让 AI Reviewer 在基线 PR 上
#      不产出（或极少产出）行级评论，从而与测试点 PR 形成对照。
#   2. 提供足够的「被引用符号」：utils / composables 导出的函数被 components /
#      pages 多处引用，为跨文件依赖分析（测试点 D3）提供真实引用图。
#   3. 附带 eslint / biome / tsconfig / package.json 配置，让 Lint/SAST
#      适配器（测试点域 G）有配置可读，不至于降级为 unavailable。
#
# 用法：
#   cd /path/to/ai-reviewer-test
#   bash scripts/gen-baseline.sh            # 生成到当前目录
#   bash scripts/gen-baseline.sh --force    # 覆盖已存在文件
#
#   生成后由你手动提交：
#     git add -A
#     git commit -m "chore: baseline project for AI reviewer testing"
#     git push origin <你的基准分支>
#
# 本脚本只写文件，绝不执行任何 git 操作。
# =============================================================================

set -euo pipefail

# ---- 参数解析 ---------------------------------------------------------------
FORCE=0
ROOT="."
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --root=*) ROOT="${arg#*=}" ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "未知参数: $arg（用 --help 查看用法）" >&2; exit 1 ;;
  esac
done

cd "$ROOT"
echo "==> 基线生成目录: $(pwd)"

# ---- 工具函数 ---------------------------------------------------------------
# write_file <path>  —— 从 stdin 读取内容写入文件；已存在且未 --force 则跳过
write_file() {
  local path="$1"
  if [[ -e "$path" && "$FORCE" -ne 1 ]]; then
    echo "  跳过（已存在，用 --force 覆盖）: $path"
    cat >/dev/null   # 消费 heredoc，避免污染后续
    return
  fi
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "  写入: $path"
}

# =============================================================================
# 1. 项目配置文件
# =============================================================================
echo "==> [1/6] 项目配置文件"

write_file "package.json" << 'EOF'
{
  "name": "ai-reviewer-test-baseline",
  "version": "1.0.0",
  "private": true,
  "description": "Baseline Nuxt/Vue + TS project for CodeSentinel AI Reviewer testing",
  "type": "module",
  "scripts": {
    "build": "nuxt build",
    "dev": "nuxt dev",
    "typecheck": "tsc --noEmit",
    "lint": "eslint ."
  },
  "dependencies": {
    "nuxt": "^3.13.0",
    "vue": "^3.5.0"
  },
  "devDependencies": {
    "@biomejs/biome": "^2.3.0",
    "eslint": "^9.15.0",
    "typescript": "^5.6.0"
  }
}
EOF

write_file "tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noImplicitAny": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": {
      "~/*": ["./*"],
      "@/*": ["./*"]
    }
  },
  "include": ["**/*.ts", "**/*.vue"],
  "exclude": ["node_modules", ".output", "dist"]
}
EOF

write_file "eslint.config.js" << 'EOF'
// 扁平配置（ESLint 9）。ai-reviewer 的 ESLint 适配器会读取此文件；
// 缺失时适配器降级为 unavailable。
export default [
  {
    files: ['**/*.ts', '**/*.vue'],
    rules: {
      'no-unused-vars': 'warn',
      'no-undef': 'error',
      'no-var': 'error',
      eqeqeq: 'warn',
      'no-eval': 'error',
      'no-console': 'warn'
    }
  }
]
EOF

write_file "biome.json" << 'EOF'
{
  "$schema": "https://biomejs.dev/schemas/2.3.0/schema.json",
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "suspicious": {
        "noExplicitAny": "warn"
      },
      "style": {
        "useConst": "warn"
      }
    }
  }
}
EOF

write_file "nuxt.config.ts" << 'EOF'
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: {enabled: true},
  typescript: {strict: true}
})
EOF

write_file ".codesentinel.yaml" << 'EOF'
# CodeSentinel 项目级配置。ai-reviewer 在 Phase 0b 读取此文件决定启用哪些工具。
tools:
  eslint:
    enabled: true
    useProjectConfig: true
  biome:
    enabled: true
  prettier:
    enabled: false
EOF

write_file ".gitignore" << 'EOF'
node_modules/
.output/
.nuxt/
dist/
*.log
.DS_Store
EOF

# =============================================================================
# 2. utils/ —— 纯工具函数（被多处引用，构成跨文件依赖图的「上游」）
# =============================================================================
echo "==> [2/6] utils/ 工具函数"

write_file "utils/formatPrice.ts" << 'EOF'
/**
 * 价格格式化工具。被 composables/useCart、components/ProductCard、
 * components/CartSummary 多处引用——是跨文件依赖分析的核心上游符号。
 */
export function formatPrice(amount: number, currency = 'CNY'): string {
  if (!Number.isFinite(amount)) {
    return '—'
  }
  return new Intl.NumberFormat('zh-CN', {style: 'currency', currency}).format(
    amount
  )
}

export function parsePrice(text: string): number {
  const cleaned = text.replace(/[^0-9.]/g, '')
  const value = Number.parseFloat(cleaned)
  return Number.isFinite(value) ? value : 0
}
EOF

write_file "utils/validators.ts" << 'EOF'
/** 通用校验工具，被 composables/useAuth 与页面表单引用。 */
export function isEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
}

export function isNonEmpty(value: string): boolean {
  return value.trim().length > 0
}

export function isInRange(n: number, min: number, max: number): boolean {
  return n >= min && n <= max
}
EOF

write_file "utils/string-helpers.ts" << 'EOF'
/** 字符串工具集合。 */
export function capitalize(input: string): string {
  if (input.length === 0) {
    return input
  }
  return input[0].toUpperCase() + input.slice(1)
}

export function truncate(input: string, max: number): string {
  return input.length > max ? `${input.slice(0, max)}…` : input
}

export function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
EOF

write_file "utils/api-client.ts" << 'EOF'
/** 极简类型化 API 客户端封装，被 composables 引用。 */
export interface ApiResult<T> {
  ok: boolean
  data?: T
  error?: string
}

export async function getJson<T>(url: string): Promise<ApiResult<T>> {
  try {
    const response = await fetch(url, {headers: {Accept: 'application/json'}})
    if (!response.ok) {
      return {ok: false, error: `HTTP ${response.status}`}
    }
    const data = (await response.json()) as T
    return {ok: true, data}
  } catch (err) {
    return {ok: false, error: err instanceof Error ? err.message : 'unknown'}
  }
}
EOF

# =============================================================================
# 3. composables/ —— Vue/Nuxt composable（引用 utils，被 components/pages 引用）
# =============================================================================
echo "==> [3/6] composables/ 组合式函数"

write_file "composables/useCart.ts" << 'EOF'
import {ref, computed} from 'vue'
import {formatPrice} from '~/utils/formatPrice'

export interface CartItem {
  id: string
  name: string
  price: number
  qty: number
}

/**
 * 购物车 composable。被 pages/cart.vue 与 components/CartSummary.vue 引用。
 * 是「composable → component」依赖链的关键节点。
 */
export function useCart() {
  const items = ref<CartItem[]>([])

  const total = computed(() =>
    items.value.reduce((sum, item) => sum + item.price * item.qty, 0)
  )

  const formattedTotal = computed(() => formatPrice(total.value))

  function addItem(item: CartItem): void {
    items.value.push(item)
  }

  function removeItem(id: string): void {
    items.value = items.value.filter(item => item.id !== id)
  }

  return {items, total, formattedTotal, addItem, removeItem}
}
EOF

write_file "composables/useAuth.ts" << 'EOF'
import {ref, computed} from 'vue'
import {isEmail, isNonEmpty} from '~/utils/validators'

/** 认证 composable。被登录页与头部组件引用。 */
export function useAuth() {
  const email = ref('')
  const password = ref('')
  const isLoggedIn = ref(false)

  const canSubmit = computed(
    () => isEmail(email.value) && isNonEmpty(password.value)
  )

  function login(): boolean {
    if (!canSubmit.value) {
      return false
    }
    isLoggedIn.value = true
    return true
  }

  function logout(): void {
    isLoggedIn.value = false
    email.value = ''
    password.value = ''
  }

  return {email, password, isLoggedIn, canSubmit, login, logout}
}
EOF

write_file "composables/useFeatureFlag.ts" << 'EOF'
import {ref} from 'vue'

export type FlagMap = Record<string, boolean>

/** 功能开关 composable。 */
export function useFeatureFlag(initial: FlagMap = {}) {
  const flags = ref<FlagMap>({...initial})

  function isEnabled(key: string): boolean {
    return flags.value[key] === true
  }

  function setFlag(key: string, value: boolean): void {
    flags.value[key] = value
  }

  return {flags, isEnabled, setFlag}
}
EOF

# =============================================================================
# 4. components/ —— Vue 组件（引用 composables 与 utils）
# =============================================================================
echo "==> [4/6] components/ 组件"

write_file "components/ProductCard.vue" << 'EOF'
<script setup lang="ts">
import {computed} from 'vue'
import {formatPrice} from '~/utils/formatPrice'

const props = defineProps<{
  name: string
  price: number
}>()

const displayPrice = computed(() => formatPrice(props.price))
</script>

<template>
  <div class="product-card">
    <h3>{{ name }}</h3>
    <span class="price">{{ displayPrice }}</span>
  </div>
</template>
EOF

write_file "components/CartSummary.vue" << 'EOF'
<script setup lang="ts">
import {useCart} from '~/composables/useCart'

const {items, formattedTotal, removeItem} = useCart()
</script>

<template>
  <div class="cart-summary">
    <ul>
      <li v-for="item in items" :key="item.id">
        {{ item.name }} × {{ item.qty }}
        <button @click="removeItem(item.id)">移除</button>
      </li>
    </ul>
    <p class="total">合计：{{ formattedTotal }}</p>
  </div>
</template>
EOF

write_file "components/AppHeader.vue" << 'EOF'
<script setup lang="ts">
import {useAuth} from '~/composables/useAuth'

const {isLoggedIn, logout} = useAuth()
</script>

<template>
  <header class="app-header">
    <nav>
      <NuxtLink to="/">首页</NuxtLink>
      <NuxtLink to="/cart">购物车</NuxtLink>
    </nav>
    <button v-if="isLoggedIn" @click="logout">退出登录</button>
  </header>
</template>
EOF

# =============================================================================
# 5. pages/ —— Nuxt 页面（引用 composables 与 components）
# =============================================================================
echo "==> [5/6] pages/ 页面"

write_file "pages/index.vue" << 'EOF'
<script setup lang="ts">
import ProductCard from '~/components/ProductCard.vue'

const products = [
  {id: 'p1', name: '机械键盘', price: 399},
  {id: 'p2', name: '人体工学椅', price: 1299}
]
</script>

<template>
  <main>
    <h1>商品列表</h1>
    <ProductCard
      v-for="p in products"
      :key="p.id"
      :name="p.name"
      :price="p.price"
    />
  </main>
</template>
EOF

write_file "pages/cart.vue" << 'EOF'
<script setup lang="ts">
import {useCart} from '~/composables/useCart'
import CartSummary from '~/components/CartSummary.vue'

const {addItem} = useCart()

function addSample(): void {
  addItem({id: 'p1', name: '机械键盘', price: 399, qty: 1})
}
</script>

<template>
  <main>
    <h1>购物车</h1>
    <button @click="addSample">加入示例商品</button>
    <CartSummary />
  </main>
</template>
EOF

# =============================================================================
# 6. server/ —— Nuxt 服务端 API（TS，供 Semgrep/服务端安全测试提供上下文）
# =============================================================================
echo "==> [6/6] server/ 服务端"

write_file "server/api/health.ts" << 'EOF'
/** 健康检查端点。基线中保持安全、无缺陷。 */
export default defineEventHandler(() => {
  return {status: 'ok', ts: Date.now()}
})
EOF

write_file "server/api/products.ts" << 'EOF'
import {formatPrice} from '~/utils/formatPrice'

const CATALOG = [
  {id: 'p1', name: '机械键盘', price: 399},
  {id: 'p2', name: '人体工学椅', price: 1299}
]

export default defineEventHandler(() => {
  return CATALOG.map(item => ({
    ...item,
    displayPrice: formatPrice(item.price)
  }))
})
EOF

write_file "app.vue" << 'EOF'
<script setup lang="ts">
import AppHeader from '~/components/AppHeader.vue'
</script>

<template>
  <div>
    <AppHeader />
    <NuxtPage />
  </div>
</template>
EOF

write_file "README.md" << 'EOF'
# ai-reviewer-test — 基准项目

由 `scripts/gen-baseline.sh` 生成的 Nuxt/Vue + TypeScript 基线项目，作为
CodeSentinel AI Reviewer 各项功能测试的 **before 状态**。

## 结构

| 目录 | 说明 |
| :--- | :--- |
| `utils/` | 纯工具函数（跨文件依赖图上游） |
| `composables/` | Vue/Nuxt 组合式函数（引用 utils） |
| `components/` | Vue 组件（引用 composables/utils） |
| `pages/` | Nuxt 页面 |
| `server/api/` | 服务端 API 端点 |

## 依赖引用图（供跨文件依赖分析测试）

```
utils/formatPrice.ts ──┬─> composables/useCart.ts ──┬─> pages/cart.vue
                       │                            └─> components/CartSummary.vue
                       ├─> components/ProductCard.vue
                       └─> server/api/products.ts
utils/validators.ts ────> composables/useAuth.ts ────> components/AppHeader.vue
```

## 用法

1. 提交本基线到基准分支（如 `main` 或 `test/dev4`）
2. 运行 `scripts/gen-testpoints.sh` 生成针对各功能域的测试变更
3. 按 `scripts/TEST-POINTS.md` 的指引创建 PR / 评论，观察 Bot 行为
EOF

# ---- 完成提示 ---------------------------------------------------------------
echo ""
echo "============================================================="
echo "  ✅ 基线项目已生成"
echo "============================================================="
echo ""
echo "下一步（由你手动执行）："
echo "  1. 检查生成的文件"
echo "  2. 提交到基准分支："
echo "       git add -A"
echo "       git commit -m \"chore: baseline project for AI reviewer testing\""
echo "       git push origin <基准分支，如 test/dev4>"
echo "  3. 基线合入后，运行测试点脚本："
echo "       bash scripts/gen-testpoints.sh --help"
echo ""
