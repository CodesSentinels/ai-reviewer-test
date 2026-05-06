# 迭代三 · Linter/SAST 集成 — 端到端测试文档

> **测试目标**: 在 `ai-reviewer-test` 仓库中通过真实 PR 验证 ai-reviewer 的 Linter/SAST
> 集成（Phase 1：JavaScript/TypeScript）。
>
> **对应功能**: [05-iteration-linter-sast.md](../../codesentinel-docs/docs/product-plan/05-iteration-linter-sast.md)
>
> **技术设计**: [06-iteration-linter-sast-design.md](../../ai-reviewer/docs/06-iteration-linter-sast-design.md)
>
> **本测试覆盖**: ESLint + Biome 集成、变更行过滤、`.codesentinel.yaml` 配置、Prompt 注入、
> 评论标注（🧰 Tools）、PR 摘要中的工具统计表、容错（缺工具时不阻塞审查）。

---

## 0. 概述

测试分为四步：

1. **检查/更新 workflow**：使 ai-reviewer 引用包含 Linter/SAST 集成的分支
2. **应用测试代码改动**：拷贝带刻意 lint 问题的 TS 文件 + 配置
3. **创建 PR 触发 CI**：观察 ai-reviewer 是否：
   - 跑出 ESLint / Biome 的扫描结果
   - 把工具发现注入 LLM Prompt 让 AI 交叉验证
   - 在评论尾部附带 "🧰 Tools" 标注
   - 在 PR 摘要中追加 "🧰 Static Analysis Summary" 表格
4. **核对每个测试场景**：对照下文场景表逐项打勾

---

## 1. 前置准备

### 1.1 Workflow 文件

确保 `.github/workflows/ai-reviewer.yml` 引用的是包含 Linter/SAST 集成的 ai-reviewer 分支
（如 `feature/lint-sast`），并且至少包含以下输入：

```yaml
name: Code Review

permissions:
  contents: read
  pull-requests: write
  issues: write

on:
  pull_request:
    types: [opened, synchronize, reopened]
  pull_request_review_comment:
    types: [created]
  issue_comment:
    types: [created]

jobs:
  review:
    runs-on: ubuntu-latest
    if: >-
      github.event_name != 'issue_comment' ||
      github.event.issue.pull_request != null
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      # 让 npx 能跑到 eslint / biome
      - uses: actions/checkout@v4
      - run: npm install --no-audit --no-fund
      - uses: CodesSentinels/ai-reviewer@feature/lint-sast
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        with:
          debug: true
          enable_lint_tools: true
          review_simple_changes: false
          review_comment_lgtm: false
          openai_heavy_model: gpt-5.4-mini
```

> ⚠️ `enable_lint_tools` 是迭代三新增的总开关，默认 `true`。本测试显式写出来便于定位问题。

### 1.2 测试用代码改动

进入 `ai-reviewer-test` 后执行：

```bash
cd ai-reviewer-test
bash test_cases/iteration3-linter-sast/code-changes/apply-changes.sh
```

脚本会：

1. 创建 `test/iter3-linter-sast` 分支
2. 在仓库根写入：
   - `.codesentinel.yaml`（开启 eslint + biome，关闭 prettier）
   - `eslint.config.js`（最小 Flat Config）
   - `biome.json`（最小 lint 配置）
3. 在 `utils/lint-test-cart.ts` 写入故意带问题的 TS 代码
4. 通过 `npm install --no-save` 装 `eslint@^9` 与 `@biomejs/biome@^2`
5. 提交、推送、创建 PR

---

## 2. 测试场景列表

每个场景包含：**预期工具发现** + **预期 AI 行为** + **观察点**。

### 2.1 场景 A — `array-callback-return` + 业务逻辑错误（强 AI 用例）

**目标代码**: `utils/lint-test-cart.ts::calculateTotal`

```ts
items.map(item => {
  total += item.quantity   // 缺 return + 错把 quantity 当价格
})
```

**预期工具发现**:

| 工具 | 规则 | 严重级别 |
|:-----|:-----|:---------|
| ESLint | `array-callback-return` | error |
| Biome | `lint/suspicious/useIterableCallbackReturn` | error |

**预期 AI 行为**:

- AI 必须对 `items.map(...)` 所在行写一条评论
- 评论中必须命名工具（"ESLint"/"Biome"）并解释影响
- AI 还必须指出**工具盲区中的业务逻辑错误**：累加 `item.quantity` 而非 `item.quantity * item.price`，导致总价完全错误
- 评论尾部附带 "🧰 Tools" 卡片

**通过条件**: 评论同时覆盖了 lint 发现 **和** 业务逻辑错误。

---

### 2.2 场景 B — `no-unused-vars` + `eqeqeq`

**目标代码**: `utils/lint-test-cart.ts::isValidItemId`

```ts
const tempData = 'reserved-for-future-use'
if (id == null) return false
```

**预期工具发现**:

| 工具 | 规则 | 严重级别 |
|:-----|:-----|:---------|
| ESLint | `no-unused-vars` | error（`tempData` 未使用） |
| ESLint | `eqeqeq` | error（应使用 `===`） |
| Biome | `lint/correctness/noUnusedVariables` | error |
| Biome | `lint/suspicious/noDoubleEquals` | error |

**预期 AI 行为**:

- 两个发现都对应到正确行
- 跨工具去重生效：同一行 `tempData` 不应同时出现 ESLint 与 Biome 两条相同评论
  （归一化规则名后视为同一问题，保留更高 severity）

**通过条件**:

- PR 摘要 "🧰 Static Analysis Summary" 表中 ESLint / Biome 各报告了 ≥ 1 个 error
- 行级评论列出工具发现（`no-unused-vars` 与 `eqeqeq`/`noDoubleEquals`）

---

### 2.3 场景 C — `no-console` + 隐藏的去重/库存问题

**目标代码**: `utils/lint-test-cart.ts::addToCart`

```ts
console.log(`adding item to cart: ${item.id}`)
cartItems.value.push(item)
```

**预期工具发现**:

| 工具 | 规则 | 严重级别 |
|:-----|:-----|:---------|
| ESLint | `no-console` | warning |

**预期 AI 行为**:

- AI 在该行评论中确认 console.log 是工具发现（warning 级别）
- AI **必须额外指出**：直接 push 不去重 + 缺少库存上限校验（这是工具检测不到的业务规则缺失）

**通过条件**: 评论同时包含工具确认 + 业务盲区补充。

---

### 2.4 场景 D — `URLSearchParams.map` 误用（与产品文档示例对齐）

**目标代码**: `utils/lint-test-cart.ts::debugQuery`

```ts
const params = new URL(url).searchParams as unknown as { ... }
params.map((value, key) => { ... })
```

**预期工具发现**:

- ESLint 默认规则集**不会**检出该问题（因 cast 后类型已变）
- Biome 也不会检出
- 这是**纯 AI 用例**：模型应识别 `URLSearchParams` 没有 `map` 方法，建议改用 `forEach`

**预期 AI 行为**:

- AI 写出明确的修复建议（`diff` 代码块），并指出运行时会崩溃
- 由于工具未发现该问题，评论尾部**不会**有 "🧰 Tools" 卡片
- 这验证了"工具盲区中由 AI 兜底"的能力

**通过条件**: 评论指出 `URLSearchParams.map` 不存在，建议 `forEach`，且**没有**误造工具标注。

---

### 2.5 场景 E — PR 摘要中的工具统计表

**观察位置**: ai-reviewer 发布的最终 Summarize 评论尾部

**预期内容**:

```markdown
<details>
<summary>🧰 Static Analysis Summary (2 tools)</summary>

_N findings on changed lines._

| Tool | Errors | Warnings | Files Scanned | Duration |
|:-----|:------:|:--------:|:-------------:|:---------|
| ESLint 9.x.x  | ≥3 | ≥1 | ≥1 | <60000ms |
| Biome 2.x.x   | ≥3 | 0  | ≥1 | <60000ms |

</details>
```

**通过条件**:

- 表格存在
- 各工具统计与实际发现数量一致（误差范围 ±1，因为某些规则可能在新版本被合并）
- Duration 列存在且为合理数值

---

### 2.6 场景 F — Prettier 关闭后不应出现在统计中

**前置**: `.codesentinel.yaml` 中 `prettier.enabled: false`

**预期**:

- 统计表中**不出现** Prettier 行（被配置过滤掉，根本不进入 detect 阶段）
- 日志中应有 `lint: 2/3 adapters enabled by config: [eslint, biome]` 之类的记录

---

### 2.7 场景 G — 工具不可用时的容错

**触发方式**: 在 workflow 中**故意不安装** `@biomejs/biome`（删除 `npm install` 步骤或改成只安装 eslint）

**预期**:

- ESLint 仍正常工作并报告问题
- Biome 在统计表中显示为 `_unavailable_`，并在 reason 列写出 `command not found: biome` 或类似信息
- 整个 review 不被打断
- 日志中能看到 `lint/biome: not available — ...` 的警告

**通过条件**: 单工具不可用不影响其他工具与整体审查流程。

---

### 2.8 场景 H — 关闭整个 Lint 阶段

**触发方式**: 在 workflow 输入中加 `enable_lint_tools: false`，重新跑同一 PR

**预期**:

- 日志：`Phase 0b: lint tools disabled by config, skipping`
- PR 摘要中**没有** "🧰 Static Analysis Summary" 区块
- 行级评论尾部**没有** "🧰 Tools" 标注
- 仅 AI 自然分析的内容存在

---

### 2.9 场景 I — 变更行过滤

**触发方式**: 在 `utils/lint-test-cart.ts` 已有的 PR 上，**只**修改某个无问题的注释行；
观察 ai-reviewer 的扫描结果

**预期**:

- 工具确实扫描了整个文件（ESLint/Biome 输出仍包含原有问题）
- 但 PR 摘要表中"findings on changed lines" 计数 = 0 或仅命中变更行附近 ±3 行的问题
- 行级评论中**只有**变更行附近的工具标注

**通过条件**: 工具发现没有"全文件刷屏"。

---

### 2.10 场景 J — `.codesentinel.yaml` 缺失时的回退

**触发方式**: 在另一分支删除 `.codesentinel.yaml`，保留 eslint.config.js + biome.json，
重新触发 review

**预期**:

- 日志：`lint config: no .codesentinel.yaml found, using adapter defaults`
- ESLint + Biome 仍按各自的 `defaultEnabled=true` 启用
- Prettier 因 `defaultEnabled=false` 仍不启用
- 行为与场景 E 一致

---

### 2.11 场景 K — 杠杆 A：无 finding 文件不消耗 prompt token

**目标**: 验证 `prompts.renderReviewFileDiff` 在 `inputs.lintContext` 为空时，
**整体移除** "Static analysis tool results" 段头与 "Static analysis cross-validation
(MANDATORY ...)" 指令，节省每次 doReview ~300 token。

**触发方式**: 在 PR 中混合两类文件：

1. `utils/lint-test-cart.ts` — 含 4 类工具发现（场景 A-D）
2. `utils/no-issue-utils.ts` — 一个干净的 TS 文件（自定义内容，故意写零问题）

```ts
// utils/no-issue-utils.ts
export function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n))
}
```

确保 ESLint + Biome 对它都报告 0 finding，且打开 `debug: true` 让 ai-reviewer 输出
`prompts so far` 等 debug 日志。

**预期**:

| 文件 | 是否注入 lint 段头 | 是否注入 MANDATORY 指令 | 工具发现条数 |
|:-----|:-----------------|:----------------------|:-----------|
| `lint-test-cart.ts` | ✅ 注入 | ✅ 注入 | ≥ 5 |
| `no-issue-utils.ts` | ❌ 不注入 | ❌ 不注入 | 0 |

观察 GitHub Action 的 debug 日志：

- `lint-test-cart.ts` 的 doReview 日志中：`injected lint context for utils/lint-test-cart.ts: NN tokens`
- `no-issue-utils.ts` 的 doReview 日志中：**不会出现** `injected lint context for ...`
- 两个文件分别走 `Prompts.renderReviewFileDiff` 时，
  `lint-test-cart.ts` 的 prompt 必须包含字符串 `"Static analysis cross-validation (MANDATORY"`，
  而 `no-issue-utils.ts` 的 prompt **必须不包含**该字符串

**通过条件**:

- 评论结果上：两文件都被审查；干净文件没有"幻觉式"的工具评论（因为 prompt 中根本没提"工具"）
- 摘要表中：ESLint/Biome 各报告 ≥ 1 个 finding（来自 `lint-test-cart.ts`），
  与 `no-issue-utils.ts` 无关
- token 节省：在调试日志中可对比两文件的 prompt 长度，干净文件的 prompt 应短约 1.0-1.5 KB

**单元测试**: 该条件路径已被
[`__tests__/lint-prompt-injection.test.ts`](../../ai-reviewer/__tests__/lint-prompt-injection.test.ts)
固化（4 个用例），可在本地直接验证：

```bash
cd ../ai-reviewer
npm test -- __tests__/lint-prompt-injection.test.ts
```

---

## 3. 测试执行顺序建议

| 步骤 | 场景 | 备注 |
|:-----|:-----|:-----|
| 1 | A、B、C、D、E、F、K | 一次主 PR 同时覆盖；最常用（K 需在该 PR 内追加干净文件） |
| 2 | G | 临时改 workflow 跑空 ESLint 时验证容错 |
| 3 | H | 改输入参数验证总开关 |
| 4 | I | 在已有 PR 上追加无关 commit 验证变更行过滤 |
| 5 | J | 删除 `.codesentinel.yaml` 验证默认值回退 |

---

## 4. 失败排查

| 现象 | 可能原因 | 排查 |
|:-----|:---------|:-----|
| 没有任何 lint 评论 | `enable_lint_tools=false` 或 workflow 没装工具 | 查日志 `Phase 0b` 行 |
| 工具统计表全部 _unavailable_ | `npx --no-install` 找不到工具 | 确认 workflow 跑过 `npm install` |
| 评论尾部 "🧰 Tools" 卡片缺失 | 工具发现不在评论行号范围内 | 查日志 `injected lint context for ...` |
| Biome JSON 解析失败 | Biome 版本输出格式变化 | 检查日志 `lint: failed to parse JSON` |
| ESLint 报"No files matching" | `eslint.config.js` 没生效 | 确认 Flat Config 文件名正确，`type: "module"` 已设 |

---

## 5. 单元测试入口

仓库内还附带三组单元测试，可在 ai-reviewer 本地直接跑（不依赖 GitHub）：

```bash
cd ../ai-reviewer
npm test -- \
  __tests__/lint-diff-filter.test.ts \
  __tests__/lint-orchestrator.test.ts \
  __tests__/lint-prompt-injection.test.ts
```

预期：

- `lint-diff-filter.test.ts`：8 个用例全部通过（unified diff 行号提取、变更窗口过滤、跨工具去重）
- `lint-orchestrator.test.ts`：4 个用例全部通过（启用/禁用、不可用工具、抛异常容错、disabled 短路）
- `lint-prompt-injection.test.ts`：4 个用例全部通过（杠杆 A：lintContext 空/非空两条路径、空白字符容忍、token 节省下界）

合并后 ai-reviewer 全部测试 198 个均通过。

---

## 6. 验收清单

| 验收项 | 通过标准 |
|:-------|:---------|
| ✅ 框架可扩展 | 新增工具仅需实现 ToolAdapter |
| ✅ ESLint 集成 | 场景 A/B/C 中 ESLint 发现正确反映 |
| ✅ Biome 集成 | 场景 A/B 中 Biome 发现正确反映 |
| ✅ 变更行过滤 | 场景 I 通过 |
| ✅ 结果注入 LLM | 场景 A/B/C 中 AI 评论命名工具并解释 |
| ✅ AI 交叉验证 | 场景 A/C 中 AI 同时覆盖工具发现 + 工具盲区 |
| ✅ 配置化 | 场景 F/J 通过 |
| ✅ 总开关 | 场景 H 通过 |
| ✅ 性能 | 各工具 Duration 列均 < 60s，统计表合计 < 3min |
| ✅ 错误容忍 | 场景 G 通过 |
| ✅ 杠杆 A：无 finding 文件零 token 浪费 | 场景 K 通过；`lint-prompt-injection.test.ts` 4 用例通过 |
