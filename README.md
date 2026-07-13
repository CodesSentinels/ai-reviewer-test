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
