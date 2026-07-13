# CodeSentinel AI Reviewer — 全功能测试点文档

> 配套脚本：`scripts/gen-baseline.sh`（基线项目）+ `scripts/gen-testpoints.sh`（测试点代码）
> 测试方式：在 `ai-reviewer-test` 仓库生成代码 → 手动建 PR / 发评论 → 观察 Bot 行为
> 两个脚本均只生成文件、打印指引，**不做任何 git 操作**，提交与触发全部由测试者手动执行。

---

## 0. 测试总流程

```
┌─ 1. 生成并提交基线 ──────────────────────────────────────────┐
│  bash scripts/gen-baseline.sh                                │
│  git add -A && git commit -m "chore: baseline" && git push   │
│  （提交到基准分支，如 test/dev4；基线 PR 上 Bot 应几乎无评论）  │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌─ 2. 生成测试点代码 ──────────────────────────────────────────┐
│  bash scripts/gen-testpoints.sh            # 全部 8 域         │
│  bash scripts/gen-testpoints.sh A D G      # 或指定域          │
│  → 生成到 test_cases/<域>/，并打印每域操作指引                 │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌─ 3. 逐域触发并核对 ──────────────────────────────────────────┐
│  按下方各域「验证点表」建 PR / 发命令 / 追问，记录 ✅/❌/⚠️     │
└──────────────────────────────────────────────────────────────┘
```

### 环境前置

| 项 | 值 |
| :--- | :--- |
| Workflow | `.github/workflows/ai-reviewer.yml` |
| 触发规则 | PR target `main` / `test/dev*`；push `main` / `test/dev*`；`issue_comment` / `pull_request_review_comment` created |
| 基准分支 | 建议 `test/dev4`（feature 分支从此拉出，PR 回此分支，不影响 main） |
| 分支解析 | PR 取 `base_ref`，push 取 `ref_name`（决定 checkout 哪个 ai-reviewer 分支代码） |
| 等待时间 | 首次审查 1~3 分钟；增量审查约 1 分钟 |
| 需改配置的用例 | A5 / C3 / D4 / D5 / F-截断 / G5 / G6 / G7 / H3 / H4（测完恢复） |

### 关键常量与默认值

| 常量 | 值 | 来源 |
| :--- | :--- | :--- |
| `max_review_comments` | 20 | action.yml |
| `max_files` | 150 | action.yml |
| `max_dependency_files` | 50 | action.yml |
| `MAX_CONVERSATION_TURNS` | 10 | conversation.ts |
| `MAX_CHAIN_CHARS` | 12000 | conversation.ts |
| bot mention 别名 | `@codesentinel` / `@ai-reviewer`（大小写不敏感） | parser.ts |
| ignore 关键词 | `@codesentinel: ignore` | review.ts |
| ACK 表情 | 🚀（`command_ack_reaction`） | action.yml |

---

## 功能域 → 源码映射总表

| 域 | 功能域 | 核心源文件 | 主要验证点 |
| :-: | :--- | :--- | :--- |
| **A** | 基础审查流程 | `review.ts`（四阶段）+ `prompts.ts` | A1~A6 |
| **B** | 增量审查 | `review.ts` highestReviewedCommitId + `review-commit-ids.ts` | B1~B3 |
| **C** | 文件过滤与限制 | `options.ts` checkPath / max_files | C1~C4 |
| **D** | 跨文件依赖分析 | `dependency-analyzer.ts` + `repo-tree.ts` | D1~D5 |
| **E** | 命令系统 | `commands/`（parser/dispatcher/permission/rate-limit/reply）+ handlers | E1~E24 |
| **F** | 对话追问 + 噪音控制 | `conversation.ts` + `noise-control.ts` + `review-dedup.ts` | F 系列 |
| **G** | Lint / SAST 集成 | `lint/`（eslint/biome/tsc/prettier/semgrep + formatter） | G1~G7 |
| **H** | Web 搜索 + Shell | `bot.ts` enableWebSearch / enableShell | H1~H4 |

---

## 域 A — 基础审查流程（P0）

`test_cases/A-basic-review/`

| # | 场景 | 验证点 | 操作 | 预期 |
| :-- | :--- | :--- | :--- | :--- |
| A1 | 新建 PR 触发 | 自动产出摘要 + 行级评论 | 提交 `insecure-handler.ts` → 建 PR | 1~3 分钟内出现顶部摘要 + 行级评论 |
| A2 | 摘要格式 | 含 Walkthrough + Changes 表格 | 检查 Bot 首条评论 | 含 `Walkthrough`、文件变更表格、`Summary by CodeSentinel` |
| A3 | 行级定位 | 评论定位到正确行 | 对比评论行号与问题行 | ±2 行内，引用代码片段可对应 |
| A4 | 发布说明 | 写回 PR 描述 | 用 `PR-BODY.md` 作 PR 描述 | 描述末尾出现 `Summary by CodeSentinel` |
| A5 | `disable_review` | 仅摘要无行级 | workflow 临时设 `disable_review: true` | 有摘要评论、无行级 review comments |
| A6 | ignore 跳过 | 无任何评论 | 用 `IGNORE-PR-BODY.md` 作 PR 描述 | Bot 完全不产出评论 |

预期行级评论覆盖：SQL 注入 / `eval` / 未 `await` / 循环内构造正则。

---

## 域 B — 增量审查（P0）

`test_cases/B-incremental/`

| # | 场景 | 验证点 | 操作 | 预期 |
| :-- | :--- | :--- | :--- | :--- |
| B1 | 增量 diff | 仅审新增变更 | 提交 `step1-math.ts` → 等审完 → 把 `step2` 内容追加到同文件 → 再 push | 第二次评论仅针对 `divide`/`power`，不重复 `add`/`multiply` |
| B2 | 已审 commit | 记录已审 SHA | 检查摘要评论 HTML 隐藏标签 | 含 `<!-- commit_ids_reviewed -->` 区块，列出已审 commit |
| B3 | full review | 全量审查 | 已审 PR 上发 `@codesentinel full review` | 覆盖 base..HEAD 全部变更 |

---

## 域 C — 文件过滤与限制（P1）

`test_cases/C-file-filter/`

| # | 场景 | 验证点 | 操作 | 预期 |
| :-- | :--- | :--- | :--- | :--- |
| C1 | 二进制排除 | 不审 .png/.zip | PR 含图片 + `keep/version.ts` | 仅 TS 被审查 |
| C2 | path 过滤 | 仅匹配路径 | 提交 `skip/styles.css` + `skip/data.json` + `keep/version.ts` | 仅 `version.ts` 出现在审查中 |
| C3 | `max_files` | 超出显示跳过 | 运行 `gen-many-files.sh`，临时设 `max_files: 3` | 摘要只审 3 个、记录跳过统计 |
| C4 | lock 排除 | `.lock` 不审 | PR 含 `pnpm-lock.yaml` / `package-lock.json` 变更 | lock 文件不出现在审查中 |

---

## 域 D — 跨文件依赖分析（P1）

`test_cases/D-cross-file/`（依赖基线的 `utils/formatPrice.ts` + `composables/useCart.ts`）

基线引用图：

```
utils/formatPrice.ts ──┬─> composables/useCart.ts ──┬─> pages/cart.vue
                       │                            └─> components/CartSummary.vue
                       ├─> components/ProductCard.vue
                       └─> server/api/products.ts
```

| # | 场景 | 验证点 | 操作 | 预期 |
| :-- | :--- | :--- | :--- | :--- |
| D1 | 改导出函数 | 提及引用方 | 用 `CHANGE-formatPrice.ts` 替换基线文件 | 审查/摘要提及 `useCart` / `ProductCard.vue` / `CartSummary.vue` / `products.ts` |
| D2 | TS import 解析 | 识别 named import | 同上 | 摘要列出 named import 引用方文件 |
| D3 | Vue/Nuxt composable | 识别 `useXxx` 引用 | 用 `CHANGE-useCart.ts` 替换基线文件 | 提及 `cart.vue` / `CartSummary.vue` 的 `total` 使用受影响 |
| D4 | 关闭依赖分析 | 无跨文件段落 | 临时设 `enable_dependency_analysis: false` | 摘要中无依赖分析段落 |
| D5 | `max_dependency_files` | 不超上限 | 设 `max_dependency_files: 2`，改被 3+ 文件引用的符号 | 最多分析 2 个引用方 |

---

## 域 E — 命令系统（P0）

`test_cases/E-commands/` — 详见 `command-sequence.md`

已注册命令：`help` / `resolve` / `review` / `full review` / `summary` / `pause` / `resume` / `configuration`
权限：多数 `minPermission=write`；`help` 与 `configuration` 为 `read`。

| # | 场景 | 验证点 | 预期 |
| :-- | :--- | :--- | :--- |
| E1 | `@codesentinel help` | 解析路由 | 回帖展示所有命令用法 |
| E2 | `@ai-reviewer help` | 别名 | 同样触发 |
| E3 | `@CodeSentinel HELP` | 大小写不敏感 | 同样触发 |
| E4 | `@codesentinel xyz` | 无效命令 | 回帖 UNKNOWN_COMMAND 提示 |
| E5 | 普通评论无 mention | 不响应 | Bot 无任何响应 |
| E6 | Bot 自评论 | 无死循环 | Bot 回帖后无二次触发 |
| E7 | write 用户 review | 权限通过 | 执行成功 |
| E8 | read 用户 review | 权限拒绝 | 回帖 FORBIDDEN |
| E9 | read 用户 configuration | read 可执行 | 执行成功 |
| E10 | 连发 5+ 次 help | 限流 | 第 N 次被限流，提示重试时间 |
| E11 | 重跑同一评论 | 幂等 | 第二次判为 DUPLICATE |
| E12 | resolve（有评论） | 批量解决 | 批量 resolve + 统计反馈 |
| E13 | resolve（无评论） | 空态 | 回帖「没有找到待解决的审查意见」 |
| E14 | review | 增量触发 | 触发增量审查 |
| E15 | full review | 全量触发 | 从 base 全量审查 |
| E16 | summary | 重生成摘要 | 顶部摘要更新 |
| E17 | pause | 暂停 | PR 写入暂停标记 |
| E18 | pause 后 push | 门禁 | 不自动触发审查 |
| E19 | resume | 恢复 | 恢复标记 |
| E20 | resume 后 push | 恢复触发 | 触发审查 |
| E21 | configuration | 展示配置 | 回帖配置表格 |
| E22 | ACK 表情 | 反馈 | 评论出现 🚀 |
| E23 | 进度反馈 | 反馈 | 先回「正在执行」，完成后更新 |
| E24 | 错误反馈 | 反馈 | 错误信息清晰、含建议 |

> E7/E8 需两个不同权限账号；E10/E11 需连发或通过 Actions 重跑观察。

---

## 域 F — 对话追问 + 噪音控制（P0/P1）

`test_cases/F-conversation-noise/` — 对话序列见 `conversation-sequence.md`

### F-噪音控制（3.3）— `quality-mixed-severity.ts`

| # | 场景 | 预期 |
| :-- | :--- | :--- |
| F3.1 | 严重级别徽标 | 评论顶部有 🚨严重 / ⚠️主要 / 📝建议 / 💡微调 |
| F3.2 | 级别排序 | critical > major > minor > nit |
| F3.3 | 评论截断 | 超过 20 条时截断，摘要提示省略数 |
| F3.4 | 截断保高优先级 | critical/major 不被丢弃 |
| F3.5 | 同类合并 | `Math.random()`×5 合并为 1~2 条 |
| F3.6 | `max_review_comments: 0` | 不截断，全部展示 |

### F-AI 去重（3.5）— `dedup-scenarios.ts`

| # | 场景 | 预期 |
| :-- | :--- | :--- |
| F5.1 | 同类多行合并 | 连续 5 行 `no-var` 合并为 1 条 |
| F5.2 | 不同类不合并 | `eval` / `console` / `eqeqeq` 各自保留 |
| F5.3 | 合并行号范围 | 覆盖第一个到最后一个违规行 |

### F-对话追问（3.1/3.2）— `conversation-anchor.ts`

| # | 场景 | 预期 |
| :-- | :--- | :--- |
| F1.1 | 行级评论追问 | Bot 引用该行 + 解释攻击场景 |
| F1.2 | 续轮追问 | 含修改建议，引用上一轮对话 |
| F1.3 | 不带 @ 回复 | Bot 不触发 |
| F1.4 | Bot 自回复 | 无无限循环 |
| F2.1 | 第 11 轮 | 提示「轮次已达上限」 |
| F2.4 | issue_comment 追问 | 不响应（仅行级 thread 支持对话） |

---

## 域 G — Lint / SAST 集成（P0）

`test_cases/G-lint-sast/`（依赖基线的 `eslint.config.js` / `biome.json` / `tsconfig.json`）

| # | 场景 | 操作 | 预期 |
| :-- | :--- | :--- | :--- |
| G1 | ESLint 注入 | 提交 `lint-violations.ts` | 评论引用 ESLint 规则名 |
| G2 | tsc 类型错误 | 同上 | 评论引用 TS 错误码（TS2304 / TS2345） |
| G3 | Biome 检测 | 同上 | 评论引用 Biome 规则（noExplicitAny / useConst） |
| G4 | 工具归因卡片 | 检查评论底部 | 含「🧰 Tools」段落列出参与工具 |
| G5 | `enable_lint_tools: false` | 临时改配置 | 无规则引用、无 Tools 卡片 |
| G6 | `enable_eslint: false` | 临时改配置 | 无 ESLint 引用，tsc/Biome 仍在 |
| G7 | Semgrep | 设 `enable_semgrep: true`，提交 `security-semgrep.ts` | 评论引用 Semgrep 规则 ID |

---

## 域 H — Web 搜索 + Shell（P2）

`test_cases/H-websearch-shell/` — 需查看 GitHub Actions 运行日志确认

| # | 场景 | 操作 | 预期 |
| :-- | :--- | :--- | :--- |
| H1 | Web 搜索 | 提交 `websearch-trigger.ts` | Analysis chain / 日志含 web_search 步骤 |
| H2 | Shell 执行 | 提交 `shell-trigger.ts` | 日志含 shell 调用记录 |
| H3 | 关闭 web | 临时设 `enable_web_search: false` | 日志无 `[web_search_debug]` |
| H4 | 关闭 shell | 临时设 `enable_shell: false` | 日志无 shell 调用 |

---

## 结果记录模板

```markdown
## AI Reviewer 全功能测试结果

测试日期：____    基准分支：____    测试者：____

| 域 | # | 场景 | 结果 | 备注 |
| :-: | :-- | :--- | :--: | :--- |
| A | A1 | 新建 PR 触发 | ✅/❌/⚠️ | |
| A | A2 | 摘要格式 | ✅/❌/⚠️ | |
| ... | ... | ... | ... | ... |
```

> 完整用例编号见上方各域表格；建议按 A→B→C→D 核心流程，再 E→F→G→H 交互与质量控制的顺序执行。
