# 跨文件依赖分析（enable_dependency_analysis）测试用例手册

本文档描述 `ai-reviewer-test` 项目中所有测试用例的文件依赖关系、PR 模拟方法和预期行为。

---

## 项目依赖图

```
src/
├── utils/
│   ├── calculator.ts    ← Case A / B 的修改目标
│   ├── formatter.ts     ← Case C 的修改目标
│   ├── validator.ts     ← Case F 的修改目标（通过 index.ts re-export）
│   ├── logger.ts        ← Case G 的修改目标（多文件引用）
│   ├── mathHelpers.ts   ← Case M 的修改目标（export default）
│   └── index.ts         ← Case H / H2 / H3（re-export + barrel file + export *）
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
│   ├── orderService.ts      → imports { calculateTotal, calculateTotalWithTax } from calculator
│   │                        → imports { logInfo, logError, logWarn } from logger
│   ├── analyticsService.ts  → import * as logger from logger  ← Case I (namespace)
│   │                        → imports { calculateTotal } from calculator
│   ├── discountService.ts   → imports { calculateTotal as calcTotal } ← Case J (符号别名)
│   │                        → imports { logInfo as log } from logger
│   ├── reportService.ts     → imports from '@/utils/calculator'  ← Case K (路径别名 @/)
│   ├── pricingAdapter.ts    → imports { calculateTotal as computeSubtotal } from '@/utils/calculator' ← Case L (组合)
│   ├── inventoryService.ts  → imports { calculateTotal } from '../utils' ← Case H2 (barrel 间接引用)
│   ├── invoiceService.ts    → import round from '../utils/mathHelpers' ← Case M (default import)
│   ├── monitorService.ts    → import * as calc from calculator ← Case I2 (namespace.symbol 模式)
│   ├── authService.ts       → imports { checkPermission } from permissionService ← Case N (循环引用)
│   └── permissionService.ts → imports { getCurrentUser } from authService ← Case N (循环引用)
│
├── pages/
│   └── CheckoutPage.tsx  → imports { TAX_RATE } from calculator
│                         → imports { formatPercent } from formatter
│
├── app/
│   └── main.ts           ← Case D 的修改目标（入口文件）
│
├── __tests__/
│   ├── calculator.test.ts ← Case E 的修改目标（测试文件）
│   └── logger.test.ts     ← Case E 的修改目标（测试文件）
│
└── python_example/       ← Case O (Python 点式相对导入)
    ├── utils/
    │   ├── __init__.py       → from .calculator import calculate_total
    │   ├── calculator.py     ← 修改目标
    │   └── formatter.py
    └── services/
        ├── __init__.py
        ├── order_service.py  → from ..utils.calculator import calculate_total as calc_total
        └── report_service.py → from ..utils import calculate_total
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

| 文件                               | 导入的符号                                            |
| ---------------------------------- | ----------------------------------------------------- |
| `src/hooks/useCart.ts`             | `calculateTotal`, `calculateTotalWithTax`, `TAX_RATE` |
| `src/components/CartSummary.tsx`   | `calculateTotal`, `TAX_RATE`, `formatPrice`           |
| `src/components/CheckoutForm.tsx`  | `calculateTotal`, `formatPrice`                       |
| `src/components/ProductCard.tsx`   | `formatPrice`                                         |
| `src/services/orderService.ts`     | `calculateTotal`, `calculateTotalWithTax`             |
| `src/services/analyticsService.ts` | `calculateTotal`                                      |
| `src/pages/CheckoutPage.tsx`       | `TAX_RATE`                                            |

**Step 6** — 引用搜索，`calculateTotal` 的引用位置：

| 文件                  | 行  | 内容                                                             |
| --------------------- | --- | ---------------------------------------------------------------- |
| `useCart.ts`          | ~39 | `const subtotal = useMemo(() => calculateTotal(items), [items])` |
| `CartSummary.tsx`     | ~29 | `const subtotal = calculateTotal(items)`                         |
| `CheckoutForm.tsx`    | ~25 | `const total = calculateTotal(items)`                            |
| `orderService.ts`     | ~26 | `const subtotal = calculateTotal(items)`                         |
| `analyticsService.ts` | ~22 | `const total = calculateTotal(items)`                            |

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

## Case A2：修改导出函数签名（破坏性变更）→ 检测到调用方报错

### 修改目标

`src/utils/calculator.ts` — 修改 `calculateTotal` 的函数签名，将原有参数改为必选新参数（破坏性变更）

### PR diff 模拟

```diff
--- a/src/utils/calculator.ts
+++ b/src/utils/calculator.ts
@@ -21,7 +21,12 @@

 /** 计算购物车总价 */
-export function calculateTotal(items: CartItem[]): number {
-  return items.reduce((sum, item) => sum + item.price * item.quantity, 0)
+export function calculateTotal(items: CartItem[], currency: Currency): Money {
+  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0)
+  return {
+    amount: subtotal,
+    currency: currency.code,
+    formatted: `${currency.symbol}${subtotal.toFixed(2)}`
+  }
 }
```

### 与 Case A 的区别

|            | Case A                    | Case A2                              |
| ---------- | ------------------------- | ------------------------------------ |
| 新参数     | `coupon?: Coupon`（可选） | `currency: Currency`（必选）         |
| 返回类型   | 不变（`number`）          | 变更（`number` → `Money`）           |
| 调用方影响 | 不报错，但需确认逻辑      | **编译报错**，所有调用方必须同步修改 |

### 预期行为

**Step 1** — 提取到修改的导出符号：`calculateTotal` (function)

**Step 2~5** — 依赖图构建，与 Case A 相同，找到以下文件导入了 `calculator.ts`：

| 文件                               | 导入的符号                                            |
| ---------------------------------- | ----------------------------------------------------- |
| `src/hooks/useCart.ts`             | `calculateTotal`, `calculateTotalWithTax`, `TAX_RATE` |
| `src/components/CartSummary.tsx`   | `calculateTotal`, `TAX_RATE`, `formatPrice`           |
| `src/components/CheckoutForm.tsx`  | `calculateTotal`, `formatPrice`                       |
| `src/services/orderService.ts`     | `calculateTotal`, `calculateTotalWithTax`             |
| `src/services/analyticsService.ts` | `calculateTotal`                                      |

**Step 6** — 引用搜索，`calculateTotal` 的引用位置：

| 文件                  | 行  | 内容                                                             | 报错原因                                                     |
| --------------------- | --- | ---------------------------------------------------------------- | ------------------------------------------------------------ |
| `useCart.ts`          | ~39 | `const subtotal = useMemo(() => calculateTotal(items), [items])` | 缺少必选参数 `currency`；返回类型不再是 `number`             |
| `CartSummary.tsx`     | ~29 | `const subtotal = calculateTotal(items)`                         | 缺少必选参数 `currency`；`subtotal` 类型不再是 `number`      |
| `CheckoutForm.tsx`    | ~25 | `const total = calculateTotal(items)`                            | 缺少必选参数 `currency`；`total` 类型不再是 `number`         |
| `orderService.ts`     | ~26 | `const subtotal = calculateTotal(items)`                         | 缺少必选参数 `currency`；后续计算 `subtotal * TAX_RATE` 报错 |
| `analyticsService.ts` | ~22 | `const total = calculateTotal(items)`                            | 缺少必选参数 `currency`；`total` 类型不再是 `number`         |

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

> ⚠️ **破坏性变更**：`calculateTotal` 新增了必选参数 `currency: Currency`，且返回类型从 `number` 变为 `Money`。
> 以下 5 处调用方会产生编译错误，必须同步修改：
>
> 1. `useCart.ts:39` — `calculateTotal(items)` 缺少 `currency` 参数，且 `subtotal` 被当作 `number` 使用
> 2. `CartSummary.tsx:29` — 同上，`subtotal` 后续参与数值计算会类型不匹配
> 3. `CheckoutForm.tsx:25` — 同上
> 4. `orderService.ts:26` — `subtotal * TAX_RATE` 将报错，因为 `subtotal` 现在是 `Money` 类型
> 5. `analyticsService.ts:22` — 同上
>
> 建议：此 PR 应同步修改所有调用方，或提供向后兼容的重载签名。

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

| 文件               | 行  | 内容                                                               |
| ------------------ | --- | ------------------------------------------------------------------ |
| `useCart.ts`       | ~41 | `const taxAmount = useMemo(() => subtotal * TAX_RATE, [subtotal])` |
| `CartSummary.tsx`  | ~30 | `const tax = subtotal * TAX_RATE`                                  |
| `CheckoutPage.tsx` | ~30 | `当前税率: {formatPercent(TAX_RATE)}`                              |

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

## Case F：有导出符号且通过 re-export 被引用 → 检测到间接依赖

### 修改目标

`src/utils/validator.ts` — 修改 `validateEmail` 的返回类型（破坏性变更）

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

日志输出：

```
dependency analysis [step 1]: analyzing 1 modified files for exported symbols
dependency analysis [step 1]: src/utils/validator.ts → 1 exported / 1 total symbols: [validateEmail(function)]
```

**Step 2** — PR 内文件扫描，无直接导入方：

```
dependency analysis [step 2]: PR-internal scan complete — 0 import relationships found (0 API calls for head content)
```

**Step 3~4** — 扫描外部候选文件：

```
dependency analysis [step 3]: scanning 28 external candidate files (API calls needed: 28)
dependency analysis [step 4]: fetched 28 external file contents (28 total in cache including 0 PR files from step 2)
```

**Step 5** — 发现 `index.ts` 通过 re-export 引用了 `validator.ts`：

```
dependency analysis [step 5]: ✓ external hit: src/utils/index.ts imports {validateEmail, validatePhone, validatePassword} from src/utils/validator.ts
dependency analysis [step 5]: external scan complete — 1 import relationships found
```

**Step 6** — 引用搜索，在 `index.ts` 中找到 `validateEmail` 的引用：

```
dependency analysis [step 6]: src/utils/validator.ts has 1 dependents, searching for references to [validateEmail]
dependency analysis [step 6]: ✓ src/utils/index.ts → 1 references found: [validateEmail:L10]
```

**汇总**：

```
dependency analysis [summary]: 1 files analyzed, 1 cross-file references found
dependency analysis [summary]: 1 files have external references, 0 files have no references (API calls used: 28)
```

**注意**：虽然没有业务文件直接 `import { validateEmail } from './validator'`，但 `src/utils/index.ts` 通过 `export { validateEmail } from './validator'` 形成了 re-export 关系，被依赖分析正确检测到。如果其他文件通过 `import { validateEmail } from '../utils'`（via index.ts）间接引用，当前分析只能追踪到 `index.ts` 层级（已知局限 #2）。

**AI 审查预期输出**：

> `validateEmail` 的返回类型从 `boolean` 变为 `{ valid: boolean; reason?: string }`，属于破坏性变更。
> `src/utils/index.ts` re-export 了该函数，任何通过 `index.ts` 间接引用的调用方都需要适配新的返回类型。

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

| 文件               | 导入方式                                                       |
| ------------------ | -------------------------------------------------------------- |
| `useCart.ts`       | `import { logInfo } from '../utils/logger'`                    |
| `CartSummary.tsx`  | `import { logInfo } from '../utils/logger'`                    |
| `CheckoutForm.tsx` | `import { logInfo, logError } from '../utils/logger'`          |
| `orderService.ts`  | `import { logInfo, logError, logWarn } from '../utils/logger'` |

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

## Case J：符号别名（import { X as Y }）→ 别名引用被正确追踪

### 修改目标

`src/utils/calculator.ts` — 修改 `calculateTotal` 的函数签名（与 Case A 相同的修改）

### 背景

`src/services/discountService.ts` 使用符号别名导入：

```typescript
import { calculateTotal as calcTotal, TAX_RATE as taxRate } from '../utils/calculator'
import { logInfo as log } from '../utils/logger'
```

代码中实际使用的是 `calcTotal()`、`taxRate`、`log()`，不是原始名称。

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

**Step 2~5** — 依赖图构建，除了 Case A 已有的文件外，还应发现 `discountService.ts`：

| 文件                              | 导入的符号                      | aliasMap                                          |
| --------------------------------- | ------------------------------- | ------------------------------------------------- |
| `src/services/discountService.ts` | `calculateTotal`, `TAX_RATE`    | `{ calculateTotal: 'calcTotal', TAX_RATE: 'taxRate' }` |

**Step 6** — 引用搜索，搜索时同时匹配原始名 `calculateTotal` 和别名 `calcTotal`：

| 文件                 | 行   | 内容                                       | 匹配方式   |
| -------------------- | ---- | ------------------------------------------ | ---------- |
| `discountService.ts` | ~24  | `const originalTotal = calcTotal(items)`   | 别名匹配   |
| `discountService.ts` | ~42  | `const total = calcTotal(items)`           | 别名匹配   |

**注入的跨文件上下文**（discountService.ts 部分）：

```markdown
### References to modified symbols:
- src/services/discountService.ts:24: const originalTotal = calcTotal(items)
- src/services/discountService.ts:42: const total = calcTotal(items)
```

**AI 审查预期输出**：

> `calculateTotal` 新增了可选参数 `coupon?: Coupon`。`discountService.ts` 中通过别名 `calcTotal` 调用了该函数 2 次（第 24、42 行），当前未传递 coupon 参数。考虑到该服务本身就在处理折扣逻辑，可能需要将 coupon 传入 `calcTotal` 调用。

### 与 Case A 的区别

|            | Case A                      | Case J                                          |
| ---------- | --------------------------- | ----------------------------------------------- |
| 导入方式   | `import { calculateTotal }` | `import { calculateTotal as calcTotal }`        |
| 代码中使用 | `calculateTotal(items)`     | `calcTotal(items)`                              |
| 搜索方式   | 直接匹配 `calculateTotal`   | 同时匹配 `calculateTotal` + 别名 `calcTotal`    |
| 修复前     | ✓ 能检测                    | ✗ 无法检测（只搜索原始名）                      |
| 修复后     | ✓ 能检测                    | ✓ 能检测（aliasMap 扩展搜索）                   |

---

## Case K：路径别名（@/ 前缀）→ 路径能被正确解析

### 修改目标

`src/utils/calculator.ts` — 修改 `calculateTotal` 的函数签名（与 Case A 相同的修改）

### 背景

`src/services/reportService.ts` 使用 `@/` 路径别名导入（tsconfig.json 配置了 `@/*` → `./src/*`）：

```typescript
import { calculateTotal, formatPrice, TAX_RATE } from '@/utils/calculator'
import { formatDate, formatPercent } from '@/utils/formatter'
import { logInfo } from '@/utils/logger'
```

### PR diff 模拟

与 Case A 相同。

### 预期行为

**Step 2~5** — `resolveImportPath` 对 `@/utils/calculator` 的解析过程：

1. 检测到 `@/` 前缀，匹配 `PATH_ALIAS_RULES`
2. 去掉前缀得到 `utils/calculator`
3. 依次尝试 `src/utils/calculator`、`app/utils/calculator`、`lib/utils/calculator`
4. `src/utils/calculator.ts` 在 `repoFilesSet` 中命中 → 返回 `src/utils/calculator.ts`

| 文件                            | 导入路径              | 解析结果                  |
| ------------------------------- | --------------------- | ------------------------- |
| `src/services/reportService.ts` | `@/utils/calculator`  | `src/utils/calculator.ts` |

**Step 6** — 引用搜索正常进行：

| 文件               | 行   | 内容                                       |
| ------------------ | ---- | ------------------------------------------ |
| `reportService.ts` | ~31  | `const subtotal = calculateTotal(items)`   |

**注入的跨文件上下文**：

```markdown
### Files that import from this file:
- src/services/reportService.ts

### References to modified symbols:
- src/services/reportService.ts:31: const subtotal = calculateTotal(items)
```

**AI 审查预期输出**：

> `calculateTotal` 新增了可选参数 `coupon?: Coupon`。`reportService.ts` 通过路径别名 `@/utils/calculator` 导入并在第 31 行调用，需确认报表场景是否需要支持优惠券。

### 与 Case A 的区别

|            | Case A                           | Case K                                  |
| ---------- | -------------------------------- | --------------------------------------- |
| 导入路径   | `../utils/calculator`（相对路径）| `@/utils/calculator`（路径别名）        |
| 解析方式   | `resolveRelativePath`            | `PATH_ALIAS_RULES` 前缀匹配            |
| 修复前     | ✓ 能解析                         | ✗ 返回 null（非 `.` 开头直接跳过）     |
| 修复后     | ✓ 能解析                         | ✓ 能解析（@/ → src/ 映射）             |

---

## Case L：路径别名 + 符号别名组合 → 两种别名同时生效

### 修改目标

`src/utils/calculator.ts` — 修改 `calculateTotal` 的函数签名

### 背景

`src/services/pricingAdapter.ts` **同时** 使用路径别名和符号别名：

```typescript
import {
  calculateTotal as computeSubtotal,
  TAX_RATE as defaultTaxRate,
  formatPrice as fmtPrice,
} from '@/utils/calculator'
import { logInfo as info, logWarn as warn } from '@/utils/logger'
```

这是最复杂的场景：路径解析需要处理 `@/` 前缀，符号追踪需要通过 `aliasMap` 匹配别名。

### PR diff 模拟

与 Case A 相同。

### 预期行为

**Step 2~5** — 路径解析 + 别名提取同时工作：

1. `@/utils/calculator` → `resolveImportPath` 通过 `PATH_ALIAS_RULES` 解析为 `src/utils/calculator.ts`
2. `parseImports` 提取 `importedSymbols: ['calculateTotal', 'TAX_RATE', 'formatPrice']`，`aliasMap: { calculateTotal: 'computeSubtotal', TAX_RATE: 'defaultTaxRate', formatPrice: 'fmtPrice' }`

| 文件                              | 导入路径             | 解析结果                  | aliasMap                                                                             |
| --------------------------------- | -------------------- | ------------------------- | ------------------------------------------------------------------------------------ |
| `src/services/pricingAdapter.ts`  | `@/utils/calculator` | `src/utils/calculator.ts` | `{ calculateTotal: 'computeSubtotal', TAX_RATE: 'defaultTaxRate', formatPrice: 'fmtPrice' }` |

**Step 6** — 搜索时同时匹配 `calculateTotal` + `computeSubtotal`：

| 文件                | 行   | 内容                                             | 匹配方式 |
| ------------------- | ---- | ------------------------------------------------ | -------- |
| `pricingAdapter.ts` | ~36  | `const subtotal = computeSubtotal(items) * rate` | 别名匹配 |

**注入的跨文件上下文**：

```markdown
### References to modified symbols:
- src/services/pricingAdapter.ts:36: const subtotal = computeSubtotal(items) * rate
```

**AI 审查预期输出**：

> `calculateTotal` 新增了可选参数 `coupon?: Coupon`。`pricingAdapter.ts` 通过路径别名 `@/utils/calculator` + 符号别名 `computeSubtotal` 导入并调用（第 36 行），当前未传递 coupon 参数。

### 两种别名的协作流程

```
源文件修改: calculateTotal 签名变更
    ↓
路径别名解析: @/utils/calculator → src/utils/calculator.ts (resolveImportPath)
    ↓
符号原始名提取: importedSymbols = ['calculateTotal'] (parseImports)
    ↓
别名映射记录: aliasMap = { calculateTotal: 'computeSubtotal' } (parseImports)
    ↓
依赖图存储: { file: 'pricingAdapter.ts', symbols: ['calculateTotal'], aliasMap: {...} }
    ↓
引用搜索扩展: searchSymbols = ['calculateTotal', 'computeSubtotal'] (analyzeDependencies step 6)
    ↓
匹配成功: computeSubtotal(items) → 引用被检测到
```

---

## Case H2：Barrel file 间接引用 → 步骤 5.5 传递追踪

### 修改目标

`src/utils/calculator.ts` — 修改 `calculateTotal` 的函数签名（与 Case A 相同）

### 背景

`src/services/inventoryService.ts` 通过 barrel file `utils/index.ts` 间接导入 `calculateTotal`：

```typescript
import { calculateTotal, formatPrice, logInfo } from '../utils'
```

`../utils` 解析到 `src/utils/index.ts`，而 `index.ts` 通过 `export { calculateTotal } from './calculator'` re-export 了 `calculateTotal`。

### 预期行为

**Step 2~5** — `inventoryService.ts` 的 import `../utils` 解析到 `src/utils/index.ts`。由于 `index.ts` 不在 `allModifiedSymbols` 中（被修改的是 `calculator.ts`），直接依赖图**不包含** `inventoryService.ts`。

**Step 5.5（新增）** — Barrel file 传递追踪：

1. `index.ts` 已在依赖图中（作为 `calculator.ts` 的 dependent）
2. 检测到 `index.ts` 包含 `export { calculateTotal } from './calculator'` → 标记为 barrel file
3. 扫描所有已获取文件，发现 `inventoryService.ts` import 了 `../utils`（解析到 `index.ts`）
4. 将 `inventoryService.ts` 加入 `calculator.ts` 的依赖图

```
dependency analysis [step 5.5]: src/utils/calculator.ts has 1 barrel file(s): [src/utils/index.ts]
dependency analysis [step 5.5]: ✓ barrel passthrough: src/services/inventoryService.ts imports {calculateTotal, formatPrice, logInfo} from barrel src/utils/index.ts ← src/utils/calculator.ts
```

**Step 6** — 引用搜索在 `inventoryService.ts` 中找到 `calculateTotal` 的调用：

| 文件                  | 行   | 内容                                           |
| --------------------- | ---- | ---------------------------------------------- |
| `inventoryService.ts` | ~23  | `const total = calculateTotal(items)`          |
| `inventoryService.ts` | ~33  | `const totalValue = calculateTotal(items)`     |

### 与 Case F 的区别

|            | Case F                              | Case H2                                          |
| ---------- | ----------------------------------- | ------------------------------------------------ |
| barrel 角色 | index.ts 是 dependent（直接引用方）  | index.ts 是 passthrough（中转站）                |
| 消费者     | 无（只到 index.ts 层级）             | inventoryService.ts（通过 barrel 间接到达）      |
| 追踪深度   | 1-hop（修改文件 → barrel）           | 2-hop（修改文件 → barrel → 消费者）              |
| 修复前     | ✓ 检测到 index.ts                   | ✗ 漏掉 inventoryService.ts                       |
| 修复后     | ✓ 检测到 index.ts                   | ✓ 步骤 5.5 追踪到 inventoryService.ts            |

---

## Case H3：export * from → 通配符 re-export 解析

### 修改目标

`src/utils/mathHelpers.ts` — 修改 `roundPrice` 的函数签名

### 背景

`src/utils/index.ts` 使用通配符 re-export：

```typescript
export * from './mathHelpers'
```

### PR diff 模拟

```diff
-export default function roundPrice(amount: number, decimals = 2): number {
+export default function roundPrice(amount: number, decimals = 2, mode: 'round' | 'floor' | 'ceil' = 'round'): number {
```

### 预期行为

**Step 5** — `export * from './mathHelpers'` 被 `parseTsImports` 的 `exportStarRe` 正则匹配，解析为 `importPath: './mathHelpers'`，`isNamespace: true`。`index.ts` 被加入 `mathHelpers.ts` 的依赖图。

**Step 5.5** — barrel passthrough 同样适用：通过 `index.ts` 间接 import mathHelpers 函数的文件也会被追踪。

---

## Case I2：namespace import → namespaceName.symbolName 精确搜索

### 修改目标

`src/utils/calculator.ts` — 修改 `calculateTotal` 的函数签名

### 背景

`src/services/monitorService.ts` 使用 namespace import：

```typescript
import * as calc from '../utils/calculator'

const total = calc.calculateTotal(items)
const formatted = calc.formatPrice(total)
```

### PR diff 模拟

与 Case A 相同。

### 预期行为

**Step 5** — `import * as calc` 被解析为 `isNamespace: true`，`importedSymbols: ['calc']`。dep entry 记录 `namespaceName: 'calc'`。

**Step 6（增强）** — 引用搜索：

1. `dep.symbols = ['calc']` 与 `symbolNames = ['calculateTotal']` 无交集 → fallback 到全量搜索
2. **新增**：检测到 `dep.namespaceName = 'calc'`，构建 `calc.calculateTotal` 加入搜索列表
3. 搜索 `\bcalc\.calculateTotal\b` → 精确匹配 `calc.calculateTotal(items)`

| 文件                 | 行   | 内容                                              | 匹配方式                |
| -------------------- | ---- | ------------------------------------------------- | ----------------------- |
| `monitorService.ts`  | ~29  | `const orderTotal = calc.calculateTotal(orderItems)` | namespace.symbol 匹配 |
| `monitorService.ts`  | ~47  | `const totalBefore = calc.calculateTotal(before)`    | namespace.symbol 匹配 |
| `monitorService.ts`  | ~48  | `const totalAfter = calc.calculateTotal(after)`      | namespace.symbol 匹配 |

### 与 Case I 的区别

|            | Case I                             | Case I2                                    |
| ---------- | ---------------------------------- | ------------------------------------------ |
| 搜索方式   | fallback 全量搜索原始符号名        | 构建 `namespaceName.symbolName` 精确搜索   |
| 精度       | 可能产生假阳性（如同名局部变量）   | 精确匹配 `calc.calculateTotal` 模式         |
| 修复前     | ✓ 能找到（靠 fallback）            | ✓ 能找到但可能有误报                        |
| 修复后     | ✓ 不变                             | ✓ 增加精确 namespace 模式搜索              |

---

## Case M：default import → 本地名引用追踪

### 修改目标

`src/utils/mathHelpers.ts` — 修改 `roundPrice`（default export）的签名

### 背景

`src/services/invoiceService.ts` 使用 default import：

```typescript
import round from '../utils/mathHelpers'

const tax = round(subtotal * TAX_RATE)
```

消费者使用本地名 `round`，而原始导出名是 `roundPrice`。

### PR diff 模拟

```diff
-export default function roundPrice(amount: number, decimals = 2): number {
+export default function roundPrice(amount: number, decimals = 2, mode: 'round' | 'floor' | 'ceil' = 'round'): number {
   const factor = Math.pow(10, decimals)
-  return Math.round(amount * factor) / factor
+  const fn = mode === 'floor' ? Math.floor : mode === 'ceil' ? Math.ceil : Math.round
+  return fn(amount * factor) / factor
 }
```

### 预期行为

**Step 1** — 提取符号：`roundPrice` (function, exported)

**Step 2~5** — `invoiceService.ts` 的 `import round from '../utils/mathHelpers'` 被解析：
- `importedSymbols: ['round']`, `isDefault: true`
- dep entry: `{ file: 'invoiceService.ts', symbols: ['round'], defaultImportName: 'round' }`

**Step 6（增强）** — 引用搜索：

1. `dep.symbols = ['round']` 与 `symbolNames = ['roundPrice']` 无交集 → fallback
2. **新增**：检测到 `dep.defaultImportName = 'round'`，将 `round` 加入搜索列表
3. 搜索 `\bround\b` → 找到所有使用 `round()` 的地方

| 文件                | 行   | 内容                                                  | 匹配方式        |
| ------------------- | ---- | ----------------------------------------------------- | --------------- |
| `invoiceService.ts` | ~31  | `const tax = round(subtotal * TAX_RATE)`              | default 本地名  |
| `invoiceService.ts` | ~32  | `const total = round(subtotal + tax)`                 | default 本地名  |
| `invoiceService.ts` | ~36  | `subtotal: formatPrice(round(subtotal)),`             | default 本地名  |
| `invoiceService.ts` | ~47  | `const discountAmount = round(subtotal * discount)`   | default 本地名  |
| `invoiceService.ts` | ~48  | `const afterDiscount = round(subtotal - discountAmount)` | default 本地名 |

**注入的跨文件上下文**：

```markdown
### Modified exports in this file:
- `roundPrice` (function)

### Files that import from this file (1):
- src/services/invoiceService.ts

### References to modified symbols:
- src/services/invoiceService.ts:31: const tax = round(subtotal * TAX_RATE)
- src/services/invoiceService.ts:32: const total = round(subtotal + tax)
- src/services/invoiceService.ts:36: subtotal: formatPrice(round(subtotal)),
- src/services/invoiceService.ts:47: const discountAmount = round(subtotal * discount)
- src/services/invoiceService.ts:48: const afterDiscount = round(subtotal - discountAmount)
```

**AI 审查预期输出**：

> `roundPrice` 新增了可选参数 `mode`，`invoiceService.ts` 通过 default import 别名 `round` 调用了 5 次。当前所有调用使用默认的 `'round'` 模式，无需修改，但建议在财务计算场景中确认是否需要使用 `'floor'` 或 `'ceil'` 模式以避免精度偏差。

### 修复前后对比

|            | 修复前                                  | 修复后                                      |
| ---------- | --------------------------------------- | ------------------------------------------- |
| 依赖检测   | ✓ invoiceService.ts 在依赖图中         | ✓ 不变                                      |
| 引用搜索   | ✗ 搜索 `roundPrice` 找不到 `round`    | ✓ 通过 `defaultImportName` 搜索 `round`    |

---

## Case N：循环引用 → 保护机制

### 修改目标

`src/services/authService.ts` — 修改 `getCurrentUser` 的签名

### 背景

`authService.ts` 和 `permissionService.ts` 形成循环引用：

```
authService.ts ──import──→ permissionService.ts（checkPermission）
      ↑                           │
      └────────import─────────────┘ （getCurrentUser）
```

### PR diff 模拟

```diff
-export function getCurrentUser(): User | null {
-  return currentUser
+export function getCurrentUser(): User | null {
+  if (!currentUser) {
+    logWarn('getCurrentUser called but no user is logged in')
+  }
+  return currentUser
 }
```

### 预期行为

**Step 1** — 提取符号：`getCurrentUser` (function)

**Step 2~5** — 发现 `permissionService.ts` import 了 `getCurrentUser` from `authService.ts`

**Step 6（增强）** — 循环引用保护：

1. `deps` 中包含 `permissionService.ts`
2. 如果 `authService.ts` 也 import 了 `permissionService.ts` 的符号，`authService.ts` 本身**不会**出现在自己的 deps 中（因为修改的文件不会被加入自己的依赖图）
3. `dep.file === modifiedFile` 的条目被跳过 → 防止自引用循环

引用搜索结果：

| 文件                    | 行   | 内容                                          |
| ----------------------- | ---- | --------------------------------------------- |
| `permissionService.ts`  | ~39  | `const user = getCurrentUser()`               |
| `permissionService.ts`  | ~49  | `const user = getCurrentUser()`               |

### 循环引用不影响分析的原因

当前分析是 1-hop：只查找"谁 import 了被修改文件"，不会递归追踪"import 了被修改文件的文件又被谁 import"。因此循环引用不会导致无限循环。步骤 6 的 `dep.file === modifiedFile` 保护是防御性编程，确保未来扩展 N-hop 时也不会出问题。

---

## Case O：Python 点式相对导入 + __init__.py

### 修改目标

`src/python_example/utils/calculator.py` — 修改 `calculate_total` 的签名

### 背景

Python 使用点式相对导入，与 JS/TS 的 `./` `../` 不同：

```python
# order_service.py
from ..utils.calculator import calculate_total as calc_total  # 两个点 = 父目录

# report_service.py
from ..utils import calculate_total  # 通过 __init__.py 间接导入
```

### PR diff 模拟

```diff
-def calculate_total(items):
-    """计算购物车总价"""
-    return sum(item["price"] * item["quantity"] for item in items)
+def calculate_total(items, coupon=None):
+    """计算购物车总价（支持优惠券）"""
+    subtotal = sum(item["price"] * item["quantity"] for item in items)
+    if coupon:
+        return subtotal * (1 - coupon["discount"])
+    return subtotal
```

### 预期行为

**Step 1** — 提取符号：`calculate_total` (function)

**parsePyImports 路径转换**：

| 原始 importPath | 转换后            | 含义               |
| --------------- | ----------------- | ------------------ |
| `..utils.calculator` | `../utils/calculator` | 父目录的 utils/calculator |
| `..utils`       | `../utils`        | 父目录的 utils（→ `__init__.py`）|
| `.calculator`   | `./calculator`    | 当前目录的 calculator |

**resolveImportPath 解析**：

| 文件                    | 导入路径              | 转换后               | 解析结果                                  |
| ----------------------- | --------------------- | -------------------- | ----------------------------------------- |
| `services/order_service.py` | `..utils.calculator` | `../utils/calculator` | `src/python_example/utils/calculator.py` |
| `services/report_service.py` | `..utils`          | `../utils`           | `src/python_example/utils/__init__.py`   |

**tryResolveWithExtensions 增强**：

- 扩展名列表增加 `.py`
- index 文件列表增加 `/__init__.py`

**Step 6** — 引用搜索：

| 文件                 | 行   | 内容                                                    | 备注         |
| -------------------- | ---- | ------------------------------------------------------- | ------------ |
| `order_service.py`   | ~16  | `subtotal = calc_total(items)`                          | 别名 calc_total |
| `order_service.py`   | ~25  | `total_revenue = sum(calc_total(order["items"]) ...)`  | 别名 calc_total |

**注意**：`report_service.py` 通过 `from ..utils import calculate_total` 间接导入（经 `__init__.py`），属于 barrel file 场景（Case H2），需要步骤 5.5 的 barrel passthrough 才能追踪。

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

| PR 内容                                                                               | 涵盖 Case   |
| ------------------------------------------------------------------------------------- | ----------- |
| 修改 `calculator.ts` (calculateTotal + TAX_RATE) + 修改 `formatter.ts` (padZero)      | A + B + C   |
| 修改 `logger.ts` (logInfo) + 修改 `main.ts` (APP_VERSION) + 修改 `calculator.test.ts` | G + D + E   |
| 修改 `validator.ts` (validateEmail) + 修改 `logger.ts` (setLogLevel)                  | F + I       |
| 修改 `calculator.ts` (calculateTotal) — 验证 discountService/reportService/pricingAdapter | A + J + K + L |
| 修改 `calculator.ts` — 验证 barrel file 间接引用追踪                                        | A + H2        |
| 修改 `mathHelpers.ts` (roundPrice) — 验证 default import + barrel export *                   | M + H3        |
| 修改 `authService.ts` (getCurrentUser) — 验证循环引用保护                                     | N             |
| 修改 `calculator.ts` — 验证 namespace.symbol 精确搜索                                        | A + I2        |
| 修改 `calculator.py` — 验证 Python 点式导入 + __init__.py                                    | O             |

---

## 配置参数参考

| 参数                         | 默认值  | 说明                                  |
| ---------------------------- | ------- | ------------------------------------- |
| `enable_dependency_analysis` | `true`  | 启用/禁用跨文件依赖分析               |
| `max_dependency_files`       | `50`    | 最大扫描外部文件数                    |
| `path_filters`               | 无      | 文件过滤规则，依赖分析也遵守          |
| `debug`                      | `false` | 开启后可在 Actions 日志中查看分析详情 |

---

## 已知局限

1. ~~**仅 TS/JS 有效**~~ → **已修复**（Case O），Python 点式相对导入（`.module`、`..module`）已支持转换，`__init__.py` 已加入 index 文件解析
2. ~~**不追踪 re-export 链**~~ → **已修复**（Case H2），步骤 5.5 实现 barrel file 1-hop 传递追踪，零额外 API 调用
3. ~~**namespace import 精度低**~~ → **已改善**（Case I2），新增 `namespaceName.symbolName` 精确搜索模式
4. ~~**tsconfig paths 不支持**~~ → **已修复**（Case K/L），支持 `@/`、`~/`、`#/` 前缀
5. ~~**符号别名不追踪**~~ → **已修复**（Case J/L），通过 `aliasMap` 同时搜索原始名和别名
6. ~~**default import 引用丢失**~~ → **已修复**（Case M），通过 `defaultImportName` 搜索本地名
7. ~~**循环引用无保护**~~ → **已修复**（Case N），step 6 跳过 `dep.file === modifiedFile`
8. **自定义 tsconfig paths 不支持**：非 `@/~/# ` 前缀的自定义路径映射（如 `@lib/xxx`、`@components/xxx`）暂不支持，需读取 tsconfig.json
9. **namespace 解构别名**：`const { foo: bar } = utils` 需要数据流分析，暂不支持
10. **N-hop 传递依赖**：当前只支持 1-hop barrel passthrough，更深层的传递链暂不追踪
11. **动态导入**：`await import('./module')` 和 `React.lazy()` 暂不解析
