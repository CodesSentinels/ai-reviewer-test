# 迭代二 · 成员 D（对话交互与噪音控制）— 端到端测试文档

> **测试目标**: 在 `ai-reviewer-test` 仓库中通过真实 PR 验证成员 D 的功能
> **对应功能**: [04-iteration-comment-interaction.md](../../ai-reviewer/docs/04-iteration-comment-interaction.md) — §2.3 对话式追问 / §2.5 噪音控制
> **技术设计**: [04-iteration-02-member-d-design.md](../../ai-reviewer/docs/04-iteration-02-member-d-design.md)
> **适用 Action 分支**: 包含成员 D 代码（`conversation.ts` / `noise-control.ts` / `command-handler.ts` 接线）的分支

---

## 0. 概述

成员 D 有两类能力，验证方式不同：

| 能力 | 是否已接入实时管线 | 验证方式 |
| :--- | :--- | :--- |
| §2.3 对话式追问 | ✅ 已接入（`command-handler` 的 `fallback_conversation` → `handleConversation`） | **真实 PR 多轮评论交互**（本文档主线） |
| §2.5 噪音控制 | ⚠️ 工具函数，待成员 C 在审查管线中调用 | **单元测试** + 手动观察（见 §4） |

主线流程 **三步走**：

1. **创建代码变更 PR**：应用 `share-link.ts`，触发初始 review 产出多条行级评论
2. **多轮追问**：在 Bot 的某条行级评论 thread 内连续 `@ai-reviewer` 追问
3. **核对预期**：上下文携带、对话连贯、轮次上限护栏

---

## 1. 前置准备

### 1.1 Workflow

本仓库 `.github/workflows/ai-reviewer.yml` 已包含所需触发器（无需改动）：

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
  pull_request_review_comment:   # ← 对话追问依赖此事件
    types: [created]
  issue_comment:
    types: [created]
permissions:
  contents: read
  pull-requests: write
  issues: write
```

> **关键**：把 `uses: CodesSentinels/ai-reviewer@<branch>` 指向**包含成员 D 代码**的分支。
> 由于 `pull_request_review_comment` / `issue_comment` 触发器只从默认分支读取 workflow，
> 改动需先合入默认分支才会生效。

### 1.2 本地工具

- `gh` CLI 已登录
- `jq` 已安装（多轮脚本依赖）

---

## 2. 第一步：生成代码并创建 PR

```bash
cd ai-reviewer-test
# 脚本仅生成代码（写入 utils/share-link.ts），不创建 PR
bash test_cases/iteration2-member-d/code-changes/apply-changes.sh

# 由你手动建分支、提交、推送、创建 PR
git checkout -b test/iter2-member-d
git add utils/share-link.ts
git commit -m "test: iter2 member-d share-link utils"
git push -u origin test/iter2-member-d
gh pr create   # 或在网页创建 PR
```

`share-link.ts` 故意包含以下问题（合法 TS，可编译运行），用于产出多条审查评论：

| 函数 | 类别 | 问题 |
| :--- | :--- | :--- |
| `SIGNING_SECRET` | 安全 | 硬编码密钥 |
| `generateShareToken` | 安全 | 弱随机数（Math.random） |
| `generateShortId` | 安全 | 弱随机数（**同类问题**，验证去重/折叠） |
| `isValidShareUrl` | 安全 | ReDoS 风险正则 |
| `parseSharePayload` | 正确性 | JSON.parse 未处理异常 |
| `paginate` | 正确性 | off-by-one |
| `trackShare` | 正确性 | 未 await 的异步副作用 |

等待自动 review 完成（约 1~3 分钟），确认 Bot 在 diff 行上产出了 **行级评论**（review comments，而非仅 PR 摘要）。

---

## 3. 第二步：多轮追问对话

```bash
# 默认 3 轮
PR=<PR编号> bash docs/run-iter2-member-d-test.sh

# DRY RUN 预览（不实际发送）
DRY=1 PR=<PR编号> bash docs/run-iter2-member-d-test.sh

# 触发轮次上限（10）观察终止提示
PR=<PR编号> ROUNDS=12 bash docs/run-iter2-member-d-test.sh
```

脚本逻辑：

1. 定位一条 Bot 的**顶层行级评论**作为对话锚点（thread root）
2. 每轮在该 thread 内回帖一个追问，然后轮询等待 Bot 在同 thread 内出现新回复
3. 打印每轮回复预览与统计

### 3.1 测试场景与预期

| # | 场景 | 操作 | 预期 Bot 响应 |
| :-- | :--- | :--- | :--- |
| 1 | 首轮追问（带 @） | thread 内回复 `@ai-reviewer 这个问题为什么严重？` | 结合**被评论代码**给出解释 |
| 2 | 续轮追问（不带 @） | thread 内回复 `那推荐的修复方式是什么？` | 仍触发回复（进行中对话即触发），延续上一轮上下文 |
| 3 | 跨调用方影响 | `如果改用你建议的方案，会影响其它调用方吗？` | 回答体现对 diff / 文件上下文的理解 |
| 4 | 普通评论不打扰 | 在 thread 外发一条**不含 @bot 且非 Bot 线程**的普通 PR 评论 | **不**触发对话回复 |
| 5 | 轮次上限 | `ROUNDS=12` 连续追问 | 第 11 轮起回复『已达对话轮次上限』并停止 |

### 3.2 人工核对要点

- **意图识别**：场景 2 未 @bot 仍回复（因 thread 内已有 Bot 评论）；场景 4 普通评论不回复。
- **上下文携带**：回答是否引用了被评论的具体函数 / 代码行。
- **对话连贯**：多轮之间是否记得前文（脚本通过同一 thread 实现）。
- **轮次护栏**：超过 `MAX_CONVERSATION_TURNS = 10` 后出现终止提示。

---

## 4. 噪音控制（§2.5）验证

噪音控制目前以**工具函数**形式交付（待成员 C 在审查管线中调用），单元测试已覆盖核心逻辑：

```bash
# 在 ai-reviewer 仓库内
cd ../ai-reviewer
npx jest __tests__/noise-control.test.ts
```

覆盖项：

| 能力 | 断言 |
| :--- | :--- |
| 同类合并 | 相同 path+category+title 合并为一条，标注『合并 N 处』，保留最高严重级别 |
| 排序+截断 | 按严重级别降序；超过 `maxComments`（默认 20）截断并返回截断数 |
| 折叠 | minor/nit/info 折叠进 `<details>`；critical/major 展开 |
| 截断提示 | 超限时追加『未展示 N 条』 |
| 汇总评论 | `buildSummaryBody` 含严重级别统计表；`postSummaryComment` 用独立 `FINDINGS_SUMMARY_TAG` 幂等替换 |

> **手动联调（C 接入后）**：审查产出 > 20 条发现时，PR 顶部应出现一条统计汇总评论，
> 行级评论按优先级截断，低优先级建议被 `<details>` 折叠，`share-link.ts` 的两处弱随机数被合并展示。

---

## 5. 故障排查

| 现象 | 可能原因 | 处理 |
| :--- | :--- | :--- |
| 脚本报『未找到 Bot 的行级审查评论』 | 初始 review 未完成 / 只生成了 PR 摘要而无行级评论 | 等待 review 完成；确认 diff 行上确有 review comments |
| 追问后 Bot 不回复 | Action 分支未含 D 代码 / 触发器未在默认分支生效 | 核对 §1.1；确认 workflow 已合入默认分支 |
| 续轮（不带 @）不回复 | 该回复未落在 Bot thread 内 | 确认回复发到了 Bot 评论的 thread（脚本已保证 root=Bot 评论） |
| 超时 | 模型耗时 > `TIMEOUT` | 增大 `TIMEOUT=180 POLL=10` |

---

## 6. 文件清单

| 文件 | 作用 |
| :--- | :--- |
| `test_cases/iteration2-member-d/code-changes/share-link.ts` | 被审查的目标代码（含多类问题） |
| `test_cases/iteration2-member-d/code-changes/apply-changes.sh` | 一键应用改动并建 PR |
| `docs/run-iter2-member-d-test.sh` | 多轮追问对话驱动脚本 |
| `docs/08-iteration2-member-d-test-case.md` | 本测试文档 |
