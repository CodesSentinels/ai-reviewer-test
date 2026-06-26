#!/bin/bash
# ============================================================================
# AI Reviewer 测试项目生成脚本 - 测试人 2（命令系统与状态管理）
# ============================================================================
# 目标：生成一个完整的 Nuxt.js 项目，包含有意的代码问题，用于测试：
#   2.1 命令解析与路由 - @codesentinel help/review/resolve 等命令
#   2.2 权限与限流 - 用户权限校验、速率限制
#   2.3 resolve 命令 - Bot 产出评论后批量解决
#   2.4 审查控制命令 - review/full review/pause/resume/summary/configuration
#   2.5 ACK 与反馈机制 - 表情确认、进度回帖
#
# 使用方式：
#   chmod +x generate-test-project.sh
#   ./generate-test-project.sh
#   然后手动提交 PR 进行测试
# ============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "🚀 开始生成 Nuxt.js 测试项目..."
echo "📁 项目目录: $PROJECT_DIR"

# ============================================================================
# 基础层 (base-layer) - 使用 Nuxt extends 实现项目继承
# ============================================================================

echo "📦 创建 base-layer (Nuxt extends)..."

mkdir -p base-layer/{components,composables,utils,plugins,middleware,layouts}

# --- base-layer/nuxt.config.ts ---
cat > base-layer/nuxt.config.ts << 'EOF'
export default defineNuxtConfig({
  components: true,
  imports: {
    dirs: ['composables', 'utils']
  }
})
EOF

# --- base-layer/components/AppHeader.vue ---
cat > base-layer/components/AppHeader.vue << 'EOF'
<template>
  <header class="app-header">
    <nav>
      <NuxtLink to="/">首页</NuxtLink>
      <NuxtLink to="/products">商品</NuxtLink>
      <NuxtLink to="/cart">购物车</NuxtLink>
      <NuxtLink to="/dashboard">仪表盘</NuxtLink>
    </nav>
    <div class="user-actions">
      <span v-if="user">{{ user.name }}</span>
      <button @click="handleLogout">退出</button>
    </div>
  </header>
</template>

<script setup lang="ts">
const { user, logout } = useAuth()

// 问题：logout 可能返回 Promise 但未 await
const handleLogout = () => {
  logout()
  navigateTo('/login')
}
</script>
EOF

# --- base-layer/components/AppFooter.vue ---
cat > base-layer/components/AppFooter.vue << 'EOF'
<template>
  <footer class="app-footer">
    <p>&copy; {{ currentYear }} AI Reviewer Test Store</p>
    <div class="footer-links">
      <a href="/terms">条款</a>
      <a href="/privacy">隐私</a>
    </div>
  </footer>
</template>

<script setup lang="ts">
// 问题：每次渲染都创建新 Date 对象，不必要的响应式计算
const currentYear = computed(() => new Date().getFullYear())
</script>
EOF

# --- base-layer/composables/useTheme.ts ---
cat > base-layer/composables/useTheme.ts << 'EOF'
export const useTheme = () => {
  const theme = useState<'light' | 'dark'>('theme', () => 'light')

  const toggleTheme = () => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
    // 问题：直接操作 DOM，应该用响应式绑定
    document.documentElement.setAttribute('data-theme', theme.value)
    localStorage.setItem('theme', theme.value)
  }

  const initTheme = () => {
    // 问题：SSR 环境下 localStorage 不可用
    const saved = localStorage.getItem('theme') as 'light' | 'dark'
    if (saved) {
      theme.value = saved
    }
  }

  return { theme, toggleTheme, initTheme }
}
EOF

# --- base-layer/composables/useApi.ts ---
cat > base-layer/composables/useApi.ts << 'EOF'
interface ApiOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  body?: any
  headers?: Record<string, string>
}

export const useApi = () => {
  const config = useRuntimeConfig()
  const baseURL = config.public.apiBase as string

  const request = async <T>(endpoint: string, options: ApiOptions = {}): Promise<T> => {
    const { method = 'GET', body, headers = {} } = options

    // 问题：没有错误处理，fetch 失败会导致未捕获异常
    const response = await $fetch<T>(`${baseURL}${endpoint}`, {
      method,
      body,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    })

    return response
  }

  return { request }
}
EOF

# --- base-layer/utils/logger.ts ---
cat > base-layer/utils/logger.ts << 'EOF'
type LogLevel = 'debug' | 'info' | 'warn' | 'error'

// 问题：全局可变状态，可能导致并发问题
let logHistory: Array<{ level: LogLevel; message: string; timestamp: number }> = []

export const logger = {
  debug(message: string) {
    this._log('debug', message)
  },
  info(message: string) {
    this._log('info', message)
  },
  warn(message: string) {
    this._log('warn', message)
  },
  error(message: string) {
    this._log('error', message)
  },
  _log(level: LogLevel, message: string) {
    const entry = { level, message, timestamp: Date.now() }
    logHistory.push(entry)
    // 问题：生产环境不应该 console.log
    console.log(`[${level.toUpperCase()}] ${message}`)
  },
  getHistory() {
    return logHistory
  },
  clear() {
    logHistory = []
  }
}
EOF

# --- base-layer/utils/validators.ts ---
cat > base-layer/utils/validators.ts << 'EOF'
export const validators = {
  // 问题：邮箱验证正则过于简单，不符合 RFC 5322
  isEmail(value: string): boolean {
    return /\S+@\S+\.\S+/.test(value)
  },

  isPhone(value: string): boolean {
    return /^1[3-9]\d{9}$/.test(value)
  },

  // 问题：密码只检查长度，没有复杂度要求
  isStrongPassword(value: string): boolean {
    return value.length >= 6
  },

  // 问题：没有 XSS 防护
  sanitizeInput(value: string): string {
    return value.trim()
  },

  isValidPrice(value: number): boolean {
    return value > 0 && Number.isFinite(value)
  }
}
EOF

# --- base-layer/middleware/auth.global.ts ---
cat > base-layer/middleware/auth.global.ts << 'EOF'
export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()
  const publicRoutes = ['/', '/login', '/register', '/products']

  if (!publicRoutes.includes(to.path) && !user.value) {
    return navigateTo('/login')
  }
})
EOF

# --- base-layer/plugins/error-handler.ts ---
cat > base-layer/plugins/error-handler.ts << 'EOF'
export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.vueApp.config.errorHandler = (error, _instance, _info) => {
    // 问题：错误处理过于简单，生产环境应上报到监控系统
    console.error('Global error:', error)
  }

  nuxtApp.hook('vue:error', (error) => {
    // 问题：吞掉了错误，没有任何处理
    console.error('Vue error:', error)
  })
})
EOF

# --- base-layer/layouts/default.vue ---
cat > base-layer/layouts/default.vue << 'EOF'
<template>
  <div class="layout-default">
    <AppHeader />
    <main class="main-content">
      <slot />
    </main>
    <AppFooter />
  </div>
</template>

<style scoped>
.layout-default {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
.main-content {
  flex: 1;
  padding: 2rem;
}
</style>
EOF

# ============================================================================
# 主项目结构
# ============================================================================

echo "📦 创建主项目结构..."

mkdir -p {components,components/ui,composables,layouts,middleware,pages,pages/products,plugins,server/api,stores,utils,types,assets/css}

# --- nuxt.config.ts (主项目，extends base-layer) ---
cat > nuxt.config.ts << 'EOF'
export default defineNuxtConfig({
  extends: ['./base-layer'],

  modules: ['@pinia/nuxt', '@vueuse/nuxt'],

  runtimeConfig: {
    // 问题：敏感信息不应有默认值
    supabaseServiceKey: 'default-service-key',
    public: {
      apiBase: 'https://api.example.com',
      supabaseUrl: 'https://xxx.supabase.co',
      supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder'
    }
  },

  devtools: { enabled: true },

  typescript: {
    strict: true
  },

  compatibilityDate: '2024-11-01'
})
EOF

# --- package.json ---
cat > package.json << 'EOF'
{
  "name": "ai-reviewer-test",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "nuxt build",
    "dev": "nuxt dev",
    "generate": "nuxt generate",
    "preview": "nuxt preview",
    "lint": "eslint .",
    "typecheck": "nuxt typecheck"
  },
  "dependencies": {
    "@pinia/nuxt": "^0.5.1",
    "@supabase/supabase-js": "^2.39.0",
    "@vueuse/core": "^10.7.0",
    "@vueuse/nuxt": "^10.7.0",
    "nuxt": "^3.13.0",
    "pinia": "^2.1.7",
    "vue": "^3.4.0",
    "vue-router": "^4.2.5"
  },
  "devDependencies": {
    "@nuxt/eslint": "^0.5.0",
    "eslint": "^9.0.0",
    "typescript": "^5.3.0"
  }
}
EOF

# --- tsconfig.json ---
cat > tsconfig.json << 'EOF'
{
  "extends": "./.nuxt/tsconfig.json",
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true
  }
}
EOF

# --- eslint.config.js ---
cat > eslint.config.js << 'EOF'
import { createConfigForNuxt } from '@nuxt/eslint-config/flat'

export default createConfigForNuxt({})
EOF

# --- .gitignore ---
cat > .gitignore << 'EOF'
node_modules
*.log
.nuxt
.nitro
.cache
.output
.env
dist
.DS_Store
EOF

# ============================================================================
# Types
# ============================================================================

cat > types/index.ts << 'EOF'
export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'user' | 'guest'
  createdAt: string
}

export interface Product {
  id: string
  name: string
  price: number
  description: string
  stock: number
  category: string
  imageUrl: string
}

export interface CartItem {
  product: Product
  quantity: number
}

export interface Order {
  id: string
  userId: string
  items: CartItem[]
  total: number
  status: 'pending' | 'paid' | 'shipped' | 'completed'
  createdAt: string
}

export interface ApiResponse<T> {
  data: T
  error?: string
  meta?: {
    total: number
    page: number
    pageSize: number
  }
}
EOF

# ============================================================================
# Composables（主项目）
# ============================================================================

echo "📦 创建 composables..."

# --- composables/useAuth.ts ---
cat > composables/useAuth.ts << 'EOF'
import type { User } from '~/types'

export const useAuth = () => {
  const user = useState<User | null>('auth-user', () => null)
  const token = useState<string | null>('auth-token', () => null)
  const loading = useState('auth-loading', () => false)

  const login = async (email: string, password: string) => {
    loading.value = true
    try {
      // 问题：密码明文传输，未做加密处理
      const response = await $fetch<{ user: User; token: string }>('/api/auth/login', {
        method: 'POST',
        body: { email, password }
      })
      user.value = response.user
      token.value = response.token
      // 问题：token 存储在 localStorage 有 XSS 风险
      if (import.meta.client) {
        localStorage.setItem('auth_token', response.token)
      }
    } catch (error: any) {
      // 问题：将服务端错误信息直接暴露给用户
      throw new Error(error.data?.message || error.message)
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    user.value = null
    token.value = null
    if (import.meta.client) {
      localStorage.removeItem('auth_token')
    }
    await navigateTo('/login')
  }

  const register = async (data: { email: string; password: string; name: string }) => {
    // 问题：没有前端输入验证
    const response = await $fetch<{ user: User; token: string }>('/api/auth/register', {
      method: 'POST',
      body: data
    })
    user.value = response.user
    token.value = response.token
  }

  return { user, token, loading, login, logout, register }
}
EOF

# --- composables/useCart.ts ---
cat > composables/useCart.ts << 'EOF'
import type { CartItem, Product } from '~/types'

export const useCart = () => {
  const items = useState<CartItem[]>('cart-items', () => [])

  const addToCart = (product: Product, quantity: number = 1) => {
    const existing = items.value.find(item => item.product.id === product.id)
    if (existing) {
      // 问题：没有检查库存是否充足
      existing.quantity += quantity
    } else {
      items.value.push({ product, quantity })
    }
    // 问题：直接修改 DOM，应该用 toast 组件
    if (import.meta.client) {
      document.title = `(${totalItems.value}) 购物车`
    }
  }

  const removeFromCart = (productId: string) => {
    items.value = items.value.filter(item => item.product.id !== productId)
  }

  const updateQuantity = (productId: string, quantity: number) => {
    // 问题：quantity 可能为负数或零
    const item = items.value.find(item => item.product.id === productId)
    if (item) {
      item.quantity = quantity
    }
  }

  const clearCart = () => {
    items.value = []
  }

  // 问题：浮点数精度问题
  const totalPrice = computed(() => {
    return items.value.reduce((sum, item) => sum + item.product.price * item.quantity, 0)
  })

  const totalItems = computed(() => {
    return items.value.reduce((sum, item) => sum + item.quantity, 0)
  })

  return { items, addToCart, removeFromCart, updateQuantity, clearCart, totalPrice, totalItems }
}
EOF

# --- composables/useFeatureFlag.ts ---
cat > composables/useFeatureFlag.ts << 'EOF'
interface FeatureFlags {
  enableNewCheckout: boolean
  enableDarkMode: boolean
  enableWebSocket: boolean
  maxCartItems: number
}

export const useFeatureFlag = () => {
  // 问题：默认值硬编码，应该从服务端获取
  const flags = useState<FeatureFlags>('feature-flags', () => ({
    enableNewCheckout: false,
    enableDarkMode: true,
    enableWebSocket: false,
    maxCartItems: 99
  }))

  const isEnabled = (flag: keyof FeatureFlags): boolean => {
    // 问题：类型断言不安全
    return flags.value[flag] as unknown as boolean
  }

  const fetchFlags = async () => {
    try {
      const response = await $fetch<FeatureFlags>('/api/feature-flags')
      flags.value = response
    } catch {
      // 问题：静默失败，功能开关获取失败应该有降级策略
      console.warn('Failed to fetch feature flags, using defaults')
    }
  }

  return { flags, isEnabled, fetchFlags }
}
EOF

# --- composables/useSupabase.ts ---
cat > composables/useSupabase.ts << 'EOF'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

let supabaseInstance: SupabaseClient | null = null

export const useSupabase = () => {
  const config = useRuntimeConfig()

  // 问题：单例在 SSR 环境下会跨请求共享状态
  if (!supabaseInstance) {
    supabaseInstance = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseAnonKey as string
    )
  }

  const uploadFile = async (bucket: string, path: string, file: File) => {
    // 问题：没有文件类型和大小验证
    const { data, error } = await supabaseInstance!.storage
      .from(bucket)
      .upload(path, file)

    if (error) throw error
    return data
  }

  const getPublicUrl = (bucket: string, path: string) => {
    // 问题：路径拼接没有安全校验，可能存在路径遍历
    const { data } = supabaseInstance!.storage
      .from(bucket)
      .getPublicUrl(path)

    return data.publicUrl
  }

  return { client: supabaseInstance!, uploadFile, getPublicUrl }
}
EOF

# ============================================================================
# Components
# ============================================================================

echo "📦 创建 components..."

# --- components/ui/BaseButton.vue ---
cat > components/ui/BaseButton.vue << 'EOF'
<template>
  <button
    :class="['btn', `btn-${variant}`, `btn-${size}`, { 'btn-loading': loading }]"
    :disabled="disabled || loading"
    @click="$emit('click', $event)"
  >
    <span v-if="loading" class="spinner" />
    <slot />
  </button>
</template>

<script setup lang="ts">
// 问题：props 类型定义中 variant 没有限制合法值范围
defineProps<{
  variant?: string
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  disabled?: boolean
}>()

defineEmits<{
  click: [event: MouseEvent]
}>()
</script>

<style scoped>
.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-primary { background: #3b82f6; color: white; }
.btn-danger { background: #ef4444; color: white; }
.btn-loading { opacity: 0.7; cursor: not-allowed; }
</style>
EOF

# --- components/ui/BaseInput.vue ---
cat > components/ui/BaseInput.vue << 'EOF'
<template>
  <div class="input-wrapper">
    <label v-if="label" :for="inputId">{{ label }}</label>
    <input
      :id="inputId"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      @input="handleInput"
    />
    <span v-if="error" class="error-text">{{ error }}</span>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue?: string | number
  label?: string
  type?: string
  placeholder?: string
  disabled?: boolean
  error?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

// 问题：每次渲染生成新 ID，导致 SSR hydration mismatch
const inputId = `input-${Math.random().toString(36).slice(2)}`

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  // 问题：没有对 type="number" 做数值转换
  emit('update:modelValue', target.value)
}
</script>
EOF

# --- components/ProductCard.vue ---
cat > components/ProductCard.vue << 'EOF'
<template>
  <div class="product-card" @click="goToProduct">
    <img :src="product.imageUrl" :alt="product.name" class="product-image" />
    <div class="product-info">
      <h3>{{ product.name }}</h3>
      <p class="price">¥{{ formatPrice(product.price) }}</p>
      <p class="stock" :class="{ 'low-stock': product.stock < 5 }">
        库存: {{ product.stock }}
      </p>
      <BaseButton variant="primary" size="sm" @click.stop="handleAddToCart">
        加入购物车
      </BaseButton>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Product } from '~/types'

const props = defineProps<{
  product: Product
}>()

const { addToCart } = useCart()
const router = useRouter()

// 问题：formatPrice 使用 toFixed 可能丢失精度
const formatPrice = (price: number): string => {
  return price.toFixed(2)
}

const goToProduct = () => {
  router.push(`/products/${props.product.id}`)
}

const handleAddToCart = () => {
  // 问题：没有检查库存是否 > 0
  addToCart(props.product)
}
</script>

<style scoped>
.product-card {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  transition: box-shadow 0.2s;
}
.product-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
.product-image {
  width: 100%;
  height: 200px;
  object-fit: cover;
}
.product-info {
  padding: 1rem;
}
.price {
  color: #ef4444;
  font-size: 1.25rem;
  font-weight: bold;
}
.low-stock {
  color: #f59e0b;
}
</style>
EOF

# --- components/CartSummary.vue ---
cat > components/CartSummary.vue << 'EOF'
<template>
  <div class="cart-summary">
    <h2>订单摘要</h2>
    <div class="summary-row" v-for="item in items" :key="item.product.id">
      <span>{{ item.product.name }} × {{ item.quantity }}</span>
      <span>¥{{ (item.product.price * item.quantity).toFixed(2) }}</span>
    </div>
    <hr />
    <div class="summary-total">
      <strong>总计</strong>
      <strong>¥{{ totalPrice.toFixed(2) }}</strong>
    </div>
    <BaseButton variant="primary" size="lg" :loading="submitting" @click="handleCheckout">
      提交订单
    </BaseButton>
  </div>
</template>

<script setup lang="ts">
const { items, totalPrice, clearCart } = useCart()
const { user } = useAuth()
const submitting = ref(false)

const handleCheckout = async () => {
  // 问题：没有二次确认
  if (!user.value) {
    navigateTo('/login')
    return
  }

  submitting.value = true
  try {
    // 问题：没有幂等性保障，网络重试可能创建重复订单
    await $fetch('/api/orders', {
      method: 'POST',
      body: {
        items: items.value,
        total: totalPrice.value
      }
    })
    clearCart()
    navigateTo('/orders/success')
  } catch (error: any) {
    // 问题：alert 不适合生产环境
    alert('提交失败: ' + error.message)
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.cart-summary {
  padding: 1.5rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.summary-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
}
.summary-total {
  display: flex;
  justify-content: space-between;
  font-size: 1.25rem;
  margin: 1rem 0;
}
</style>
EOF

# --- components/ReviewPanel.vue ---
cat > components/ReviewPanel.vue << 'EOF'
<template>
  <div class="review-panel">
    <h3>商品评价</h3>
    <div v-if="reviews.length === 0" class="no-reviews">暂无评价</div>
    <div v-for="review in reviews" :key="review.id" class="review-item">
      <div class="review-header">
        <span class="reviewer">{{ review.userName }}</span>
        <span class="rating">{{ '⭐'.repeat(review.rating) }}</span>
        <span class="date">{{ formatDate(review.createdAt) }}</span>
      </div>
      <!-- 问题：v-html 直接渲染用户输入，存在 XSS 漏洞 -->
      <div class="review-content" v-html="review.content" />
    </div>
    <form @submit.prevent="submitReview" class="review-form">
      <textarea v-model="newReview" placeholder="写下你的评价..." rows="3" />
      <select v-model="newRating">
        <option :value="1">1星</option>
        <option :value="2">2星</option>
        <option :value="3">3星</option>
        <option :value="4">4星</option>
        <option :value="5">5星</option>
      </select>
      <BaseButton variant="primary" type="submit">提交评价</BaseButton>
    </form>
  </div>
</template>

<script setup lang="ts">
interface Review {
  id: string
  userName: string
  rating: number
  content: string
  createdAt: string
}

const props = defineProps<{
  productId: string
}>()

const reviews = ref<Review[]>([])
const newReview = ref('')
const newRating = ref(5)

const fetchReviews = async () => {
  // 问题：没有分页，大量评价会导致性能问题
  reviews.value = await $fetch<Review[]>(`/api/products/${props.productId}/reviews`)
}

// 问题：日期格式化没有国际化支持
const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString()
}

const submitReview = async () => {
  // 问题：没有防止重复提交
  await $fetch(`/api/products/${props.productId}/reviews`, {
    method: 'POST',
    body: { content: newReview.value, rating: newRating.value }
  })
  newReview.value = ''
  await fetchReviews()
}

onMounted(fetchReviews)
</script>

<style scoped>
.review-panel {
  margin-top: 2rem;
}
.review-item {
  padding: 1rem 0;
  border-bottom: 1px solid #e5e7eb;
}
.review-header {
  display: flex;
  gap: 1rem;
  align-items: center;
  margin-bottom: 0.5rem;
}
.reviewer { font-weight: bold; }
.date { color: #6b7280; font-size: 0.875rem; }
.review-form {
  margin-top: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
</style>
EOF

# --- components/DashboardStats.vue ---
cat > components/DashboardStats.vue << 'EOF'
<template>
  <div class="dashboard-stats">
    <div class="stat-card" v-for="stat in stats" :key="stat.label">
      <span class="stat-value">{{ stat.value }}</span>
      <span class="stat-label">{{ stat.label }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Stat {
  label: string
  value: string | number
}

// 问题：轮询间隔过短，可能导致服务器压力过大
const stats = ref<Stat[]>([])
let pollTimer: ReturnType<typeof setInterval> | null = null

const fetchStats = async () => {
  try {
    stats.value = await $fetch<Stat[]>('/api/dashboard/stats')
  } catch {
    // 静默失败
  }
}

onMounted(() => {
  fetchStats()
  // 问题：每 3 秒轮询一次太频繁，且未在组件销毁时清理
  pollTimer = setInterval(fetchStats, 3000)
})

onUnmounted(() => {
  if (pollTimer) {
    clearInterval(pollTimer)
  }
})
</script>

<style scoped>
.dashboard-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}
.stat-card {
  padding: 1.5rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  display: flex;
  flex-direction: column;
  align-items: center;
}
.stat-value {
  font-size: 2rem;
  font-weight: bold;
  color: #3b82f6;
}
.stat-label {
  color: #6b7280;
  margin-top: 0.5rem;
}
</style>
EOF

# --- components/NotificationBell.vue ---
cat > components/NotificationBell.vue << 'EOF'
<template>
  <div class="notification-bell" @click="togglePanel">
    <span class="bell-icon">🔔</span>
    <span v-if="unreadCount > 0" class="badge">{{ unreadCount }}</span>
    <div v-if="showPanel" class="notification-panel">
      <div v-for="notif in notifications" :key="notif.id" class="notif-item"
           :class="{ unread: !notif.read }"
           @click="markAsRead(notif.id)">
        <p>{{ notif.message }}</p>
        <span class="notif-time">{{ notif.createdAt }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Notification {
  id: string
  message: string
  read: boolean
  createdAt: string
}

const showPanel = ref(false)
const notifications = ref<Notification[]>([])

// 问题：每次重新计算都遍历整个数组
const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

const togglePanel = () => {
  showPanel.value = !showPanel.value
}

const markAsRead = async (id: string) => {
  // 问题：乐观更新没有回滚机制
  const notif = notifications.value.find(n => n.id === id)
  if (notif) notif.read = true

  await $fetch(`/api/notifications/${id}/read`, { method: 'POST' })
}

// 问题：WebSocket 连接没有重连逻辑
const connectWebSocket = () => {
  if (import.meta.client) {
    const ws = new WebSocket('wss://api.example.com/notifications')
    ws.onmessage = (event) => {
      const notif = JSON.parse(event.data) as Notification
      notifications.value.unshift(notif)
    }
  }
}

onMounted(() => {
  connectWebSocket()
})
</script>

<style scoped>
.notification-bell {
  position: relative;
  cursor: pointer;
}
.badge {
  position: absolute;
  top: -5px;
  right: -5px;
  background: #ef4444;
  color: white;
  border-radius: 50%;
  width: 18px;
  height: 18px;
  font-size: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
}
.notification-panel {
  position: absolute;
  top: 100%;
  right: 0;
  width: 300px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  max-height: 400px;
  overflow-y: auto;
  z-index: 100;
}
.notif-item {
  padding: 0.75rem;
  border-bottom: 1px solid #f3f4f6;
}
.notif-item.unread {
  background: #eff6ff;
}
</style>
EOF

# ============================================================================
# Pages
# ============================================================================

echo "📦 创建 pages..."

# --- pages/index.vue ---
cat > pages/index.vue << 'EOF'
<template>
  <div class="home-page">
    <section class="hero">
      <h1>欢迎来到测试商城</h1>
      <p>AI Reviewer 命令系统测试项目</p>
    </section>
    <section class="featured-products">
      <h2>推荐商品</h2>
      <div class="product-grid">
        <ProductCard v-for="product in products" :key="product.id" :product="product" />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { Product } from '~/types'

// 问题：SEO meta 硬编码，未使用 i18n
useHead({
  title: '首页 - 测试商城',
  meta: [{ name: 'description', content: '这是一个测试商城' }]
})

// 问题：没有错误处理和加载状态
const { data: products } = await useFetch<Product[]>('/api/products', {
  default: () => []
})
</script>

<style scoped>
.hero {
  text-align: center;
  padding: 4rem 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 12px;
  margin-bottom: 2rem;
}
.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
}
</style>
EOF

# --- pages/products/[id].vue ---
cat > pages/products/[id].vue << 'EOF'
<template>
  <div class="product-detail" v-if="product">
    <div class="product-gallery">
      <img :src="product.imageUrl" :alt="product.name" />
    </div>
    <div class="product-info">
      <h1>{{ product.name }}</h1>
      <p class="price">¥{{ product.price.toFixed(2) }}</p>
      <p class="description">{{ product.description }}</p>
      <div class="quantity-selector">
        <button @click="quantity--" :disabled="quantity <= 1">-</button>
        <span>{{ quantity }}</span>
        <button @click="quantity++">+</button>
      </div>
      <BaseButton variant="primary" @click="handleAdd">加入购物车</BaseButton>
    </div>
    <ReviewPanel :product-id="product.id" />
  </div>
  <div v-else class="loading">加载中...</div>
</template>

<script setup lang="ts">
import type { Product } from '~/types'

const route = useRoute()
const { addToCart } = useCart()
const quantity = ref(1)

// 问题：route.params.id 类型不安全，可能为数组
const { data: product } = await useFetch<Product>(`/api/products/${route.params.id}`)

const handleAdd = () => {
  if (product.value) {
    // 问题：quantity 没有上限校验
    addToCart(product.value, quantity.value)
  }
}
</script>

<style scoped>
.product-detail {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
}
.product-gallery img {
  width: 100%;
  border-radius: 8px;
}
.price {
  font-size: 1.5rem;
  color: #ef4444;
  font-weight: bold;
}
.quantity-selector {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin: 1rem 0;
}
.quantity-selector button {
  width: 32px;
  height: 32px;
  border: 1px solid #d1d5db;
  border-radius: 4px;
  background: white;
  cursor: pointer;
}
</style>
EOF

# --- pages/cart.vue ---
cat > pages/cart.vue << 'EOF'
<template>
  <div class="cart-page">
    <h1>购物车</h1>
    <div v-if="items.length === 0" class="empty-cart">
      <p>购物车是空的</p>
      <NuxtLink to="/products">去逛逛</NuxtLink>
    </div>
    <div v-else class="cart-layout">
      <div class="cart-items">
        <div v-for="item in items" :key="item.product.id" class="cart-item">
          <img :src="item.product.imageUrl" :alt="item.product.name" class="item-image" />
          <div class="item-info">
            <h3>{{ item.product.name }}</h3>
            <p class="item-price">¥{{ item.product.price.toFixed(2) }}</p>
          </div>
          <div class="item-quantity">
            <button @click="updateQuantity(item.product.id, item.quantity - 1)">-</button>
            <span>{{ item.quantity }}</span>
            <button @click="updateQuantity(item.product.id, item.quantity + 1)">+</button>
          </div>
          <button class="remove-btn" @click="removeFromCart(item.product.id)">删除</button>
        </div>
      </div>
      <CartSummary />
    </div>
  </div>
</template>

<script setup lang="ts">
const { items, updateQuantity, removeFromCart } = useCart()

useHead({
  title: `购物车(${items.value.length}) - 测试商城`
})
</script>

<style scoped>
.cart-layout {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
}
.cart-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
}
.item-image {
  width: 80px;
  height: 80px;
  object-fit: cover;
  border-radius: 4px;
}
.item-quantity {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.remove-btn {
  color: #ef4444;
  background: none;
  border: none;
  cursor: pointer;
}
</style>
EOF

# --- pages/dashboard.vue ---
cat > pages/dashboard.vue << 'EOF'
<template>
  <div class="dashboard-page">
    <h1>仪表盘</h1>
    <DashboardStats />
    <section class="recent-orders">
      <h2>最近订单</h2>
      <table class="orders-table">
        <thead>
          <tr>
            <th>订单号</th>
            <th>金额</th>
            <th>状态</th>
            <th>日期</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="order in orders" :key="order.id">
            <td>{{ order.id }}</td>
            <td>¥{{ order.total.toFixed(2) }}</td>
            <td>
              <span :class="['status-badge', `status-${order.status}`]">
                {{ statusMap[order.status] }}
              </span>
            </td>
            <td>{{ new Date(order.createdAt).toLocaleDateString() }}</td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { Order } from '~/types'

definePageMeta({
  middleware: 'auth'
})

const statusMap: Record<string, string> = {
  pending: '待支付',
  paid: '已支付',
  shipped: '已发货',
  completed: '已完成'
}

// 问题：没有分页加载
const { data: orders } = await useFetch<Order[]>('/api/orders', {
  default: () => []
})
</script>

<style scoped>
.orders-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 1rem;
}
.orders-table th, .orders-table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid #e5e7eb;
}
.status-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.875rem;
}
.status-pending { background: #fef3c7; color: #92400e; }
.status-paid { background: #d1fae5; color: #065f46; }
.status-shipped { background: #dbeafe; color: #1e40af; }
.status-completed { background: #e5e7eb; color: #374151; }
</style>
EOF

# --- pages/login.vue ---
cat > pages/login.vue << 'EOF'
<template>
  <div class="login-page">
    <form class="login-form" @submit.prevent="handleLogin">
      <h2>登录</h2>
      <BaseInput
        v-model="email"
        label="邮箱"
        type="email"
        placeholder="请输入邮箱"
        :error="errors.email"
      />
      <BaseInput
        v-model="password"
        label="密码"
        type="password"
        placeholder="请输入密码"
        :error="errors.password"
      />
      <BaseButton variant="primary" type="submit" :loading="loading">
        登录
      </BaseButton>
      <p class="register-link">
        没有账号？<NuxtLink to="/register">去注册</NuxtLink>
      </p>
    </form>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'auth'
})

const { login, loading } = useAuth()
const email = ref('')
const password = ref('')
const errors = reactive({ email: '', password: '' })

const handleLogin = async () => {
  // 问题：前端验证不够严格
  errors.email = ''
  errors.password = ''

  if (!email.value) {
    errors.email = '请输入邮箱'
    return
  }
  if (!password.value) {
    errors.password = '请输入密码'
    return
  }

  try {
    await login(email.value, password.value)
    navigateTo('/dashboard')
  } catch (error: any) {
    // 问题：将错误信息直接展示，可能泄露系统信息
    errors.email = error.message
  }
}
</script>

<style scoped>
.login-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 80vh;
}
.login-form {
  width: 100%;
  max-width: 400px;
  padding: 2rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.register-link {
  text-align: center;
  margin-top: 1rem;
}
</style>
EOF

# ============================================================================
# Stores (Pinia)
# ============================================================================

echo "📦 创建 stores..."

# --- stores/userStore.ts ---
cat > stores/userStore.ts << 'EOF'
import { defineStore } from 'pinia'
import type { User } from '~/types'

interface UserState {
  currentUser: User | null
  preferences: {
    language: string
    currency: string
    notifications: boolean
  }
}

export const useUserStore = defineStore('user', {
  state: (): UserState => ({
    currentUser: null,
    preferences: {
      language: 'zh-CN',
      currency: 'CNY',
      notifications: true
    }
  }),

  getters: {
    isAdmin(): boolean {
      return this.currentUser?.role === 'admin'
    },
    displayName(): string {
      return this.currentUser?.name || '游客'
    }
  },

  actions: {
    setUser(user: User) {
      this.currentUser = user
    },

    async updatePreferences(prefs: Partial<UserState['preferences']>) {
      // 问题：乐观更新没有错误回滚
      Object.assign(this.preferences, prefs)
      await $fetch('/api/user/preferences', {
        method: 'PUT',
        body: this.preferences
      })
    },

    // 问题：没有处理并发调用的情况
    async fetchUser() {
      const user = await $fetch<User>('/api/user/me')
      this.currentUser = user
    }
  }
})
EOF

# --- stores/productStore.ts ---
cat > stores/productStore.ts << 'EOF'
import { defineStore } from 'pinia'
import type { Product } from '~/types'

export const useProductStore = defineStore('products', {
  state: () => ({
    products: [] as Product[],
    loading: false,
    currentPage: 1,
    totalPages: 0,
    searchQuery: '',
    selectedCategory: ''
  }),

  getters: {
    filteredProducts(): Product[] {
      let result = this.products
      if (this.searchQuery) {
        // 问题：用 includes 做搜索，没有防抖，大数据量性能差
        result = result.filter(p =>
          p.name.includes(this.searchQuery) || p.description.includes(this.searchQuery)
        )
      }
      if (this.selectedCategory) {
        result = result.filter(p => p.category === this.selectedCategory)
      }
      return result
    }
  },

  actions: {
    async fetchProducts(page: number = 1) {
      this.loading = true
      try {
        const response = await $fetch<{ data: Product[]; totalPages: number }>('/api/products', {
          params: { page, pageSize: 20 }
        })
        // 问题：每次请求都替换整个列表，导致之前的数据丢失（应追加）
        this.products = response.data
        this.totalPages = response.totalPages
        this.currentPage = page
      } finally {
        this.loading = false
      }
    },

    async deleteProduct(id: string) {
      // 问题：没有确认弹窗，直接删除
      await $fetch(`/api/products/${id}`, { method: 'DELETE' })
      this.products = this.products.filter(p => p.id !== id)
    }
  }
})
EOF

# ============================================================================
# Server API
# ============================================================================

echo "📦 创建 server API..."

mkdir -p server/api/auth server/api/products

# --- server/api/products/index.get.ts ---
cat > server/api/products/index.get.ts << 'EOF'
import type { Product } from '~/types'

const mockProducts: Product[] = [
  {
    id: '1',
    name: 'TypeScript 入门教程',
    price: 49.9,
    description: '从零开始学习 TypeScript',
    stock: 100,
    category: 'books',
    imageUrl: '/images/ts-book.png'
  },
  {
    id: '2',
    name: 'Vue.js 实战',
    price: 69.9,
    description: 'Vue 3 + Composition API 完整指南',
    stock: 50,
    category: 'books',
    imageUrl: '/images/vue-book.png'
  },
  {
    id: '3',
    name: '机械键盘',
    price: 299.0,
    description: '87键 Cherry MX 红轴',
    stock: 3,
    category: 'electronics',
    imageUrl: '/images/keyboard.png'
  }
]

export default defineEventHandler((event) => {
  const query = getQuery(event)
  const page = Number(query.page) || 1
  const pageSize = Number(query.pageSize) || 20

  // 问题：没有对 page/pageSize 做安全校验
  const start = (page - 1) * pageSize
  const data = mockProducts.slice(start, start + pageSize)

  return {
    data,
    totalPages: Math.ceil(mockProducts.length / pageSize)
  }
})
EOF

# --- server/api/auth/login.post.ts ---
cat > server/api/auth/login.post.ts << 'EOF'
export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  // 问题：硬编码的测试凭据
  if (body.email === 'admin@test.com' && body.password === 'admin123') {
    return {
      user: {
        id: '1',
        email: body.email,
        name: 'Admin',
        role: 'admin',
        createdAt: new Date().toISOString()
      },
      // 问题：token 生成方式不安全
      token: Buffer.from(`${body.email}:${Date.now()}`).toString('base64')
    }
  }

  throw createError({
    statusCode: 401,
    // 问题：错误信息暴露了用户是否存在
    statusMessage: '用户不存在或密码错误'
  })
})
EOF

# --- server/api/webhook.ts ---
cat > server/api/webhook.ts << 'EOF'
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const headers = getHeaders(event)

  // 问题：webhook 签名验证缺失
  // 应该验证 x-hub-signature-256 头部

  // 问题：没有幂等性处理
  const eventType = headers['x-github-event']

  switch (eventType) {
    case 'push':
      // 处理推送事件
      console.log('Push event received:', body.ref)
      break
    case 'pull_request':
      // 处理 PR 事件
      console.log('PR event:', body.action, body.pull_request?.title)
      break
    default:
      // 问题：不识别的事件类型应该返回 2xx 而不是记录后继续
      console.log('Unknown event type:', eventType)
  }

  return { received: true }
})
EOF

# --- server/api/orders.post.ts ---
cat > server/api/orders.post.ts << 'EOF'
export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  // 问题：没有验证用户身份（从 token 获取 userId）
  // 问题：没有验证订单总额是否与商品价格一致（防止篡改）
  // 问题：没有库存扣减的原子性保障

  const order = {
    id: `ORD-${Date.now()}`,
    userId: 'unknown',
    items: body.items,
    total: body.total,
    status: 'pending',
    createdAt: new Date().toISOString()
  }

  // 模拟保存
  console.log('New order created:', order.id)

  return order
})
EOF

# ============================================================================
# Middleware
# ============================================================================

echo "📦 创建 middleware..."

# --- middleware/auth.ts ---
cat > middleware/auth.ts << 'EOF'
export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    // 问题：returnUrl 未编码可能导致 open redirect
    return navigateTo(`/login?returnUrl=${to.fullPath}`)
  }
})
EOF

# --- middleware/admin.ts ---
cat > middleware/admin.ts << 'EOF'
export default defineNuxtRouteMiddleware((_to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    return navigateTo('/login')
  }

  // 问题：仅前端权限检查，没有后端验证
  if (user.value.role !== 'admin') {
    return abortNavigation()
  }
})
EOF

# ============================================================================
# Plugins
# ============================================================================

echo "📦 创建 plugins..."

# --- plugins/auth.client.ts ---
cat > plugins/auth.client.ts << 'EOF'
export default defineNuxtPlugin(async () => {
  const { user } = useAuth()

  // 问题：从 localStorage 读取 token 并直接使用，没有验证有效性
  const token = localStorage.getItem('auth_token')
  if (token) {
    try {
      const response = await $fetch<{ user: any }>('/api/auth/verify', {
        headers: { Authorization: `Bearer ${token}` }
      })
      user.value = response.user
    } catch {
      // token 过期，清理
      localStorage.removeItem('auth_token')
    }
  }
})
EOF

# --- plugins/analytics.client.ts ---
cat > plugins/analytics.client.ts << 'EOF'
export default defineNuxtPlugin((nuxtApp) => {
  // 问题：直接将用户行为数据发送到外部服务，没有脱敏
  nuxtApp.hook('page:finish', () => {
    const route = useRoute()
    const { user } = useAuth()

    // 问题：没有检查用户是否同意数据收集（GDPR）
    fetch('https://analytics.example.com/track', {
      method: 'POST',
      body: JSON.stringify({
        page: route.fullPath,
        userId: user.value?.id,
        email: user.value?.email,
        timestamp: Date.now()
      }),
      keepalive: true
    }).catch(() => {
      // 静默失败
    })
  })
})
EOF

# ============================================================================
# Utils
# ============================================================================

echo "📦 创建 utils..."

# --- utils/formatPrice.ts ---
cat > utils/formatPrice.ts << 'EOF'
// 问题：浮点数精度处理不当
export const formatPrice = (price: number): string => {
  return `¥${price.toFixed(2)}`
}

// 问题：没有处理负数和溢出
export const calculateDiscount = (price: number, discountPercent: number): number => {
  return price * (1 - discountPercent / 100)
}

// 问题：简单的字符串拼接，没有国际化支持
export const formatCurrency = (amount: number, currency: string = 'CNY'): string => {
  if (currency === 'CNY') return `¥${amount.toFixed(2)}`
  if (currency === 'USD') return `$${amount.toFixed(2)}`
  return `${amount.toFixed(2)} ${currency}`
}
EOF

# --- utils/crypto-helper.ts ---
cat > utils/crypto-helper.ts << 'EOF'
// 问题：自定义加密函数，不应该自己实现加密
export const hashPassword = (password: string): string => {
  let hash = 0
  for (let i = 0; i < password.length; i++) {
    const char = password.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32bit integer
  }
  return hash.toString(16)
}

// 问题：Math.random 不是密码学安全的随机数生成器
export const generateToken = (length: number = 32): string => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let result = ''
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

// 问题：没有 timing-safe 比较
export const verifyToken = (provided: string, expected: string): boolean => {
  return provided === expected
}
EOF

# --- utils/date-helper.ts ---
cat > utils/date-helper.ts << 'EOF'
// 问题：没有时区处理
export const formatDate = (date: string | Date): string => {
  const d = new Date(date)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export const formatDateTime = (date: string | Date): string => {
  const d = new Date(date)
  return `${formatDate(d)} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

// 问题：相对时间计算没有考虑时区和国际化
export const timeAgo = (date: string | Date): string => {
  const now = Date.now()
  const past = new Date(date).getTime()
  const diff = now - past

  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 0) return `${days}天前`
  if (hours > 0) return `${hours}小时前`
  if (minutes > 0) return `${minutes}分钟前`
  return '刚刚'
}
EOF

# --- utils/api-client.ts ---
cat > utils/api-client.ts << 'EOF'
interface RequestConfig {
  baseURL?: string
  timeout?: number
  retries?: number
}

class ApiClient {
  private baseURL: string
  private timeout: number
  private retries: number

  constructor(config: RequestConfig = {}) {
    this.baseURL = config.baseURL || ''
    this.timeout = config.timeout || 30000
    this.retries = config.retries || 0
  }

  async get<T>(url: string, params?: Record<string, any>): Promise<T> {
    return this.request<T>('GET', url, { params })
  }

  async post<T>(url: string, body?: any): Promise<T> {
    return this.request<T>('POST', url, { body })
  }

  async put<T>(url: string, body?: any): Promise<T> {
    return this.request<T>('PUT', url, { body })
  }

  async delete<T>(url: string): Promise<T> {
    return this.request<T>('DELETE', url)
  }

  private async request<T>(method: string, url: string, options: any = {}): Promise<T> {
    let lastError: Error | null = null

    // 问题：重试逻辑对所有请求都重试，POST 等非幂等请求不应重试
    for (let attempt = 0; attempt <= this.retries; attempt++) {
      try {
        const response = await $fetch<T>(`${this.baseURL}${url}`, {
          method: method as any,
          ...options,
          timeout: this.timeout
        })
        return response
      } catch (error: any) {
        lastError = error
        // 问题：没有指数退避
        if (attempt < this.retries) {
          await new Promise(resolve => setTimeout(resolve, 1000))
        }
      }
    }

    throw lastError
  }
}

export const apiClient = new ApiClient({
  baseURL: '/api',
  retries: 3,
  timeout: 10000
})
EOF

# ============================================================================
# Layouts（主项目覆盖）
# ============================================================================

# --- layouts/auth.vue ---
cat > layouts/auth.vue << 'EOF'
<template>
  <div class="layout-auth">
    <div class="auth-container">
      <div class="auth-brand">
        <NuxtLink to="/">
          <h1>AI Reviewer 测试商城</h1>
        </NuxtLink>
      </div>
      <slot />
    </div>
  </div>
</template>

<style scoped>
.layout-auth {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: #f3f4f6;
}
.auth-container {
  width: 100%;
  max-width: 480px;
  padding: 2rem;
}
.auth-brand {
  text-align: center;
  margin-bottom: 2rem;
}
</style>
EOF

# ============================================================================
# App entry
# ============================================================================

# --- app.vue ---
cat > app.vue << 'EOF'
<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>

<script setup lang="ts">
useHead({
  titleTemplate: '%s - AI Reviewer Test',
  htmlAttrs: { lang: 'zh-CN' }
})
</script>
EOF

# ============================================================================
# Assets
# ============================================================================

cat > assets/css/main.css << 'EOF'
:root {
  --color-primary: #3b82f6;
  --color-danger: #ef4444;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-text: #1f2937;
  --color-text-light: #6b7280;
  --color-border: #e5e7eb;
  --color-bg: #ffffff;
  --color-bg-secondary: #f9fafb;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  color: var(--color-text);
  background: var(--color-bg);
  line-height: 1.6;
}

a {
  color: var(--color-primary);
  text-decoration: none;
}
EOF

# ============================================================================
# GitHub Action 配置（已有 .github 目录）
# ============================================================================

echo "📦 检查 .github 目录..."

mkdir -p .github/workflows

# 确保 workflows 目录存在但不覆盖已有配置
if [ ! -f .github/workflows/ai-review.yml ]; then
cat > .github/workflows/ai-review.yml << 'EOF'
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]
  issue_comment:
    types: [created]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: AI Review
        uses: ./ai-reviewer
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          openai_api_key: ${{ secrets.OPENAI_API_KEY }}
EOF
fi

# ============================================================================
# CodeSentinel 配置文件
# ============================================================================

cat > .codesentinel.yaml << 'EOF'
# AI Reviewer (CodeSentinel) 配置
# 用于测试命令系统功能

# 审查语言
language: "zh-CN"

# 文件过滤
path_filters:
  - "!node_modules/**"
  - "!.nuxt/**"
  - "!dist/**"
  - "!*.lock"
  - "src/**"
  - "components/**"
  - "composables/**"
  - "pages/**"
  - "server/**"
  - "stores/**"
  - "utils/**"
  - "base-layer/**"

# 审查设置
max_files: 50
max_review_comments: 20

# 依赖分析
enable_dependency_analysis: true
max_dependency_files: 10

# Lint 工具
enable_lint_tools: true
enable_eslint: true

# 功能开关
enable_web_search: true
enable_shell: false
EOF

# ============================================================================
# 测试命令参考文档
# ============================================================================

mkdir -p docs

cat > docs/command-test-guide.md << 'EOF'
# 测试人 2 - 命令系统测试指南

## 测试前提
确保 AI Reviewer Bot 已正确配置并能响应 PR 事件。

## 测试步骤

### 第一阶段：提交代码触发审查
1. 执行本脚本生成测试代码
2. 提交所有变更并创建 PR
3. 等待 Bot 自动审查，产出行级评论（供后续 resolve 测试使用）

### 第二阶段：命令系统测试

在 PR 评论中按顺序执行以下命令：

```
# 2.1 命令解析与路由
@codesentinel help                    → 期望：展示所有命令用法
@ai-reviewer help                     → 期望：别名同样触发
@codesentinel invalidcmd              → 期望：提示无效命令
@CodeSentinel HELP                    → 期望：大小写不敏感

# 2.2 权限（需不同权限账号）
# write 权限用户执行 review → 期望成功
# read 权限用户执行 review → 期望 FORBIDDEN

# 2.3 resolve 命令
@codesentinel resolve                 → 期望：批量解决 Bot 评论 + 统计

# 2.4 审查控制命令
@codesentinel review                  → 期望：触发增量审查
@codesentinel full review             → 期望：全量审查
@codesentinel summary                 → 期望：重新生成摘要
@codesentinel configuration           → 期望：展示当前配置

# 2.4 暂停/恢复
@codesentinel pause                   → 期望：PR 描述写入暂停标记
（push 新 commit）                     → 期望：不自动触发审查
@codesentinel resume                  → 期望：恢复审查
（push 新 commit）                     → 期望：触发审查

# 2.5 ACK 反馈
观察每个命令执行时：
- 评论上是否出现 🚀 表情
- 耗时命令是否有进度回帖
- 错误信息是否清晰

# 限流测试
快速连续发送 5 次 @codesentinel help    → 期望：被限流
```

### 第三阶段：增量审查验证

1. 在 Bot 完成首次审查后
2. 修改一个文件（如 utils/formatPrice.ts）并 push
3. 使用 `@codesentinel review` 触发增量审查
4. 验证仅审查新增变更

## 预期产出

| 测试点 | 命令 | 期望行为 |
|--------|------|----------|
| 2.1.1 | `@codesentinel help` | 展示所有命令 |
| 2.1.2 | `@ai-reviewer help` | 别名触发 |
| 2.1.3 | `@codesentinel xyz` | 无效命令提示 |
| 2.1.6 | `@CodeSentinel HELP` | 大小写不敏感 |
| 2.3.1 | `@codesentinel resolve` | 批量解决 |
| 2.4.1 | `@codesentinel review` | 增量审查 |
| 2.4.2 | `@codesentinel full review` | 全量审查 |
| 2.4.3 | `@codesentinel summary` | 重新摘要 |
| 2.4.4 | `@codesentinel pause` | 暂停标记 |
| 2.4.6 | `@codesentinel resume` | 恢复审查 |
| 2.4.7 | `@codesentinel configuration` | 配置展示 |
EOF

# ============================================================================
# 完成
# ============================================================================

echo ""
echo "✅ 测试项目生成完成！"
echo ""
echo "📁 项目结构："
echo "  ├── base-layer/          (Nuxt extends 基础层)"
echo "  │   ├── components/"
echo "  │   ├── composables/"
echo "  │   ├── utils/"
echo "  │   ├── plugins/"
echo "  │   ├── middleware/"
echo "  │   ├── layouts/"
echo "  │   └── nuxt.config.ts"
echo "  ├── components/          (主项目组件)"
echo "  │   └── ui/"
echo "  ├── composables/         (主项目 composables)"
echo "  ├── layouts/             (主项目 layouts)"
echo "  ├── middleware/          (路由中间件)"
echo "  ├── pages/               (页面路由)"
echo "  ├── plugins/             (Nuxt 插件)"
echo "  ├── server/api/          (Nitro API)"
echo "  ├── stores/              (Pinia stores)"
echo "  ├── utils/               (工具函数)"
echo "  ├── types/               (类型定义)"
echo "  ├── assets/css/          (样式)"
echo "  ├── docs/                (测试文档)"
echo "  ├── .codesentinel.yaml   (Bot 配置)"
echo "  ├── nuxt.config.ts       (extends base-layer)"
echo "  └── package.json"
echo ""
echo "📋 下一步操作："
echo "  1. git add -A"
echo "  2. git commit -m 'feat: add nuxt.js test project for command system testing'"
echo "  3. 创建 PR 到 main 分支"
echo "  4. 等待 Bot 审查产出评论"
echo "  5. 按 docs/command-test-guide.md 执行命令测试"
echo ""
echo "⚠️  注意：项目包含大量有意的代码问题，用于触发 AI Reviewer 产出评论"
echo "    这些评论是后续 resolve/review 命令测试的前提条件"
