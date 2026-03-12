# 跨文件依赖分析（enable_dependency_analysis）测试用例手册

本文档描述 `ai-reviewer-test` 项目中所有测试用例的文件依赖关系、PR 模拟方法和预期行为。

---

## 项目依赖图

```
src/
├── utils/
│   ├── calculator.ts    ← Case A / B 的修改目标
│   ├── formatter.ts     ← Case C 的修改目标
│   ├── validator.ts     ← Case F 的修改目标（无人引用）
│   ├── logger.ts        ← Case G 的修改目标（多文件引用）
│   └── index.ts         ← Case H 的修改目标（re-export）
│
├── hooks/
│   └── useCart.ts        → imports { calculateTotal, TAX_RATE } from calculator
│                         → imports { logInfo } from logger
│
├── components/
│   ├── CartSummary.tsx   → imports { calculateTotal, TAX_RATE, formatPrice } from calculator
│   │                     → imports { formatPercent } from formatter
│   │                     → imports { logInfo } from logger
│   ├── CheckoutForm.tsx  → imports { calculateTotal, formatPrice } from calculator
│   │                     → imports { logInfo, logError } from logger
│   └── ProductCard.tsx   → imports { formatPrice } from calculator
│                         → imports { truncateText } from formatter
│
├── services/
│   ├── orderService.ts   → imports { calculateTotal, calculateTotalWithTax } from calculator
│   │                     → imports { logInfo, logError, logWarn } from logger
│   └── analyticsService.ts → import * as logger from logger  (namespace)
│                            → imports { calculateTotal } from calculator
│
├── pages/
│   └── CheckoutPage.tsx  → imports { TAX_RATE } from calculator
│                         → imports { formatPercent } from formatter
│
├── app/
│   └── main.ts           ← Case D 的修改目标（入口文件）
│
└── __tests__/
    ├── calculator.test.ts ← Case E 的修改目标（测试文件）
    └── logger.test.ts     ← Case E 的修改目标（测试文件）
```

---

## Case A：修改导出函数签名 → 检测到多个调用方

### 修改目标

`src/utils/calculator.ts` — 修改 `calculateTotal` 的函数签名

### PR diff 模拟

```diff
--- a/src/utils/calculator.ts
+++ b/src/utils/calculator.ts
@@ -21,7 +21,11 @@

 /** 计算购物车总价 */
-export function calculateTotal(items: CartItem[]): number {
-  return items.reduce((sum, item) => sum + item.price * item.quantity, 0)
+export function calculateTotal(items: CartItem[], coupon?: Coupon): number {
+  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0)
+  if (coupon) {
+    return subtotal * (1 - coupon.discount)
+  }
+  return subtotal
 }
```

### 预期行为

**Step 1** — 提取到修改的导出符号：`calculateTotal` (function)

**Step 2~5** — 依赖图构建，找到以下文件导入了 `calculator.ts`：

| 文件 | 导入的符号 |
|------|-----------|
| `src/hooks/useCart.ts` | `calculateTotal`, `calculateTotalWithTax`, `TAX_RATE` |
| `src/components/CartSummary.tsx` | `calculateTotal`, `TAX_RATE`, `formatPrice` |
| `src/components/CheckoutForm.tsx` | `calculateTotal`, `formatPrice` |
| `src/components/ProductCard.tsx` | `formatPrice` |
| `src/services/orderService.ts` | `calculateTotal`, `calculateTotalWithTax` |
| `src/services/analyticsService.ts` | `calculateTotal` |
| `src/pages/CheckoutPage.tsx` | `TAX_RATE` |

**Step 6** — 引用搜索，`calculateTotal` 的引用位置：

| 文件 | 行 | 内容 |
|------|-----|------|
| `useCart.ts` | ~39 | `const subtotal = useMemo(() => calculateTotal(items), [items])` |
| `CartSummary.tsx` | ~29 | `const subtotal = calculateTotal(items)` |
| `CheckoutForm.tsx` | ~25 | `const total = calculateTotal(items)` |
| `orderService.ts` | ~26 | `const subtotal = calculateTotal(items)` |
| `analyticsService.ts` | ~22 | `const total = calculateTotal(items)` |

**注入的跨文件上下文**：

```markdown
### Modified exports in this file:
- `calculateTotal` (function)

### Files that import from this file (7):
- src/hooks/useCart.ts
- src/components/CartSummary.tsx
- src/components/CheckoutForm.tsx
- src/components/ProductCard.tsx
- src/services/orderService.ts
- src/services/analyticsService.ts
- src/pages/CheckoutPage.tsx

### References to modified symbols:
- src/hooks/useCart.ts:39: const subtotal = useMemo(() => calculateTotal(items), [items])
- src/components/CartSummary.tsx:29: const subtotal = calculateTotal(items)
- src/components/CheckoutForm.tsx:25: const total = calculateTotal(items)
- src/services/orderService.ts:26: const subtotal = calculateTotal(items)
- src/services/analyticsService.ts:22: const total = calculateTotal(items)
```

**AI 审查预期输出**：

> `calculateTotal` 新增了可选参数 `coupon?: Coupon`，以下 5 处调用方均未传递此参数。
> 由于参数可选，现有调用不会报错，但需确认是否需要在调用方同步支持优惠券逻辑。

---

## Case B：修改导出常量值 → 检测到值变更影响

### 修改目标

`src/utils/calculator.ts` — 修改 `TAX_RATE` 的值

### PR diff 模拟

```diff
-export const TAX_RATE = 0.08
+export const TAX_RATE = 0.1
```

### 预期行为

**Step 1** — 提取符号：`TAX_RATE` (variable)

**Step 6** — `TAX_RATE` 的引用位置：

| 文件 | 行 | 内容 |
|------|-----|------|
| `useCart.ts` | ~41 | `const taxAmount = useMemo(() => subtotal * TAX_RATE, [subtotal])` |
| `CartSummary.tsx` | ~30 | `const tax = subtotal * TAX_RATE` |
| `CheckoutPage.tsx` | ~30 | `当前税率: {formatPercent(TAX_RATE)}` |

**AI 审查预期**：提醒税率从 8% 改为 10%，影响 3 处计算/展示。

---

## Case C：修改内部函数（不导出）→ 不触发跨文件分析

### 修改目标

`src/utils/formatter.ts` — 修改内部函数 `padZero`（没有 `export`）

### PR diff 模拟

```diff
-function padZero(num: number): string {
-  return num < 10 ? `0${num}` : `${num}`
+function padZero(num: number, width = 2): string {
+  return String(num).padStart(width, '0')
 }
```

### 预期行为

**Step 1** — `padZero` 没有 `export` 关键字 → `extractModifiedSymbols` 返回的符号中 `isExported = false` → 被过滤，不加入 `allModifiedSymbols`

**结果**：该文件在 step 1 直接被跳过，日志输出：
```
dependency analysis [step 1]: src/utils/formatter.ts → no modified exports (1 internal symbols), skipping
```

不产生任何 API 调用，不注入跨文件上下文。

---

## Case D：修改入口文件 → isEntryPointFile 跳过

### 修改目标

`src/app/main.ts` — 修改 `APP_VERSION` 或 `initApp`

### PR diff 模拟

```diff
-export const APP_VERSION = '1.0.0'
+export const APP_VERSION = '2.0.0'
+
+/** 新增健康检查 */
+export function healthCheck(): boolean {
+  return true
+}
```

### 预期行为

**Step 1** — 提取符号：`APP_VERSION` (variable), `healthCheck` (function)

**Step 1.5** — `main.ts` 匹配 `isEntryPointFile` 规则 → 日志输出：
```
dependency analysis [step 1.5]: ✗ skipping src/app/main.ts (entry point file — imports others but is not imported)
```

**结果**：该文件被排除，不进行依赖扫描。

---

## Case E：修改测试文件 → isTestFile 跳过

### 修改目标

`src/__tests__/calculator.test.ts` — 修改导出的 `createMockItem` 函数

### PR diff 模拟

```diff
-export function createMockItem(overrides: Partial<CartItem> = {}): CartItem {
+export function createMockItem(overrides: Partial<CartItem> = {}, count = 1): CartItem {
   return {
-    id: 'test-1',
+    id: `test-${count}`,
     name: 'Test Item',
```

### 预期行为

**Step 1** — 提取符号：`createMockItem` (function, exported)

**Step 1.5** — `__tests__/calculator.test.ts` 匹配 `isTestFile` 规则 → 日志输出：
```
dependency analysis [step 1.5]: ✗ skipping src/__tests__/calculator.test.ts (test file — not imported by production code)
```

**结果**：该文件被排除，不进行依赖扫描。

---

## Case F：有导出符号但无文件引用 → 引用搜索为空

### 修改目标

`src/utils/validator.ts` — 修改 `validateEmail` 的实现

### PR diff 模拟

```diff
-export function validateEmail(email: string): boolean {
-  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
+export function validateEmail(email: string): { valid: boolean; reason?: string } {
+  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
+  if (!re.test(email)) {
+    return { valid: false, reason: '邮箱格式不正确' }
+  }
+  return { valid: true }
 }
```

### 预期行为

**Step 1** — 提取符号：`validateEmail` (function, exported)

**Step 2~5** — 扫描所有候选文件，但没有任何文件 `import { validateEmail } from './validator'`

**Step 6** — 依赖图中 `validator.ts` 的 dependents 为空 → 日志输出：
```
dependency analysis [step 6]: ✗ src/utils/validator.ts has 0 dependents — no files import it, skipping reference search
```

**结果**：`fileAnalyses` 中 `references = []`，不注入跨文件上下文。但 AI 仍然能审查 `validateEmail` 返回类型变更（从 `boolean` 变为对象），只是不会提及跨文件影响。

---

## Case G：多文件导入同一模块 → 去重 + 多引用聚合

### 修改目标

`src/utils/logger.ts` — 修改 `logInfo` 的签名

### PR diff 模拟

```diff
-export function logInfo(msg: string, ...args: unknown[]): void {
-  log('info', msg, ...args)
+export function logInfo(msg: string, context?: string, ...args: unknown[]): void {
+  log('info', context ? `[${context}] ${msg}` : msg, ...args)
 }
```

### 预期行为

**Step 1** — 提取符号：`logInfo` (function)

**Step 2~5** — 找到 4+ 个文件导入了 `logInfo`：

| 文件 | 导入方式 |
|------|---------|
| `useCart.ts` | `import { logInfo } from '../utils/logger'` |
| `CartSummary.tsx` | `import { logInfo } from '../utils/logger'` |
| `CheckoutForm.tsx` | `import { logInfo, logError } from '../utils/logger'` |
| `orderService.ts` | `import { logInfo, logError, logWarn } from '../utils/logger'` |

**去重验证**：`CheckoutForm.tsx` 和 `orderService.ts` 各只出现一次（即使它们导入了多个符号）

**Step 6** — `logInfo` 的引用汇总来自多个文件，AI 能看到完整影响面。

---

## Case H：re-export 链 → export { X } from 被正确解析

### 修改目标

`src/utils/index.ts` — 修改 re-export 列表（如新增导出）

### PR diff 模拟

```diff
 export { calculateTotal, calculateTotalWithTax, formatPrice, TAX_RATE } from './calculator'
+export { roundToTwo } from './calculator'
```

### 预期行为

**Step 1** — 由于 `export { roundToTwo } from './calculator'` 是新增行中的导出语句，`extractTsSymbols` 不会匹配 `export { ... } from` 形式（它只匹配 `export function/const/class` 等声明）→ 不提取符号

**结果**：re-export 语句的变更不会被当作"修改导出符号"来追踪，这是正确行为（真正的修改在源文件 calculator.ts，不在 re-export 文件）。

**注意**：如果想测试 `parseImports` 对 re-export 的解析能力，可以在其他文件中通过 `import { X } from '../utils'`（via index.ts）来验证间接导入是否能被解析到 `./calculator`。当前 `resolveImportPath` 会将 `../utils` 解析到 `src/utils/index.ts`，但不会继续追踪到 `calculator.ts`。这是已知的设计局限。

---

## Case I：namespace import → 引用搜索 fallback

### 修改目标

`src/utils/logger.ts` — 修改 `setLogLevel`

### 背景

`src/services/analyticsService.ts` 使用 `import * as logger from '../utils/logger'`，不列出具体符号名。

### PR diff 模拟

```diff
-export function setLogLevel(level: LogLevel): void {
-  currentLogLevel = level
+export function setLogLevel(level: LogLevel, persist = false): void {
+  currentLogLevel = level
+  if (persist) {
+    localStorage.setItem('log_level', level)
+  }
 }
```

### 预期行为

**Step 5** — `analyticsService.ts` 的 `import * as logger` 被解析为 `isNamespace: true`，`importedSymbols: ['logger']`

**Step 6** — `dep.symbols = ['logger']`，与 `symbolNames = ['setLogLevel']` 无交集 → fallback 到全量搜索 → 在文件中搜索 `setLogLevel` → 找到：
```
analyticsService.ts:36: logger.setLogLevel(level)
```

---

## 测试执行方法

### 方法 1：创建真实 PR

1. 在 `ai-reviewer-test` 仓库中从 `main` 分支创建功能分支
2. 按照上述 Case 的 diff 修改对应文件
3. 提交并创建 PR → AI Reviewer workflow 自动运行
4. 在 PR 评论中查看审查结果，验证跨文件上下文是否正确注入

### 方法 2：debug 模式验证日志

在 workflow 中设置 `debug: true`，查看 Actions 日志中的以下关键输出：

```
# Step 1: 符号提取
dependency analysis [step 1]: src/utils/calculator.ts → 1 exported / 1 total symbols: [calculateTotal(function)]

# Step 1.5: 智能过滤
dependency analysis [step 1.5]: ✗ skipping src/app/main.ts (entry point file)

# Step 2: PR 内文件分析
dependency analysis [step 2]: ✓ PR-internal hit: src/hooks/useCart.ts imports {calculateTotal, ...} from src/utils/calculator.ts

# Step 5: 外部文件分析
dependency analysis [step 5]: ✓ external hit: src/services/orderService.ts imports {calculateTotal, ...} from src/utils/calculator.ts

# Step 6: 引用搜索
dependency analysis [step 6]: ✓ src/hooks/useCart.ts → 1 references found: [calculateTotal:L39]

# 注入
injected cross-file context for src/utils/calculator.ts: 342 tokens
```

### 方法 3：组合 Case 测试

在一个 PR 中同时修改多个文件，验证复合场景：

| PR 内容 | 涵盖 Case |
|---------|----------|
| 修改 `calculator.ts` (calculateTotal + TAX_RATE) + 修改 `formatter.ts` (padZero) | A + B + C |
| 修改 `logger.ts` (logInfo) + 修改 `main.ts` (APP_VERSION) + 修改 `calculator.test.ts` | G + D + E |
| 修改 `validator.ts` (validateEmail) + 修改 `logger.ts` (setLogLevel) | F + I |

---

## 配置参数参考

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `enable_dependency_analysis` | `true` | 启用/禁用跨文件依赖分析 |
| `max_dependency_files` | `50` | 最大扫描外部文件数 |
| `path_filters` | 无 | 文件过滤规则，依赖分析也遵守 |
| `debug` | `false` | 开启后可在 Actions 日志中查看分析详情 |

---

## 已知局限

1. **仅 TS/JS 有效**：`resolveImportPath` 只处理相对路径（`./`、`../`），Python/Go/Java 的绝对导入无法解析
2. **不追踪 re-export 链**：通过 `index.ts` 间接导入的关系只能解析到 `index.ts` 本身
3. **namespace import 精度低**：`import * as X` 时无法知道具体使用了哪些符号，fallback 到全量搜索
4. **tsconfig paths 不支持**：如 `@/utils/calculator` 这类别名路径无法解析