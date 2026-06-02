# 迭代二 · 成员 C — 手动测试说明

> 目标：在 `ai-reviewer-test` 的真实 PR 中，手动验证 ai-reviewer 成员 C 的审查控制能力。

覆盖命令：

- `@aireviewer help`
- `@aireviewer summary`
- `@codesentinel review`
- `@aireviewer full review`
- `@aireviewer pause`
- `@aireviewer configuration`
- `@aireviewer resume`

---

## 0. 前置检查

确认 `.github/workflows/ai-reviewer.yml` 满足下面条件：

- `on.pull_request` 已启用。
- `on.issue_comment` 已启用。
- `permissions.issues: write` 已配置。
- `permissions.pull-requests: write` 已配置。
- `uses: CodesSentinels/ai-reviewer@<ref>` 指向包含成员 C 改动的分支或 commit。

建议每发一个耗时命令后，等对应 GitHub Action 完成再发下一个，避免互相取消。

---

## 1. 创建测试 PR

在 `ai-reviewer-test` 仓库根目录手动执行：

```bash
git checkout -b test/iter2-member-c-manual
```

新建文件 `utils/review-control-checkout.ts`：

```ts
export interface ReviewControlCartLine {
  id: string
  title: string
  price: number
  quantity: number
  selected: boolean
  discountRate?: number
}

export interface ReviewControlOrder {
  id: string
  total: number
  lineCount: number
}

export async function createReviewControlOrder(
  lines: ReviewControlCartLine[],
  sendAnalytics: (event: string, payload: Record<string, unknown>) => Promise<void>
): Promise<ReviewControlOrder> {
  const total = calculateReviewControlTotal(lines)

  // 故意问题：未 await，analytics 失败时调用方无法知道。
  sendAnalytics('review-control-order-created', {total, lineCount: lines.length})

  return {
    id: `order-${Date.now()}`,
    total,
    lineCount: lines.length
  }
}

export function calculateReviewControlTotal(lines: ReviewControlCartLine[]): number {
  let total = 0
  for (const line of lines) {
    if (!line.selected) continue
    // 故意问题：忽略 quantity，多个同款商品会被少算。
    total += line.price
  }
  return Number(total.toFixed(2))
}

export function applyReviewControlDiscount(total: number, discountRate = 0): number {
  // 故意问题：discountRate 没有限制范围，传入 2 会得到负数总价。
  return Number((total - total * discountRate).toFixed(2))
}
```

提交并创建 PR：

```bash
git add utils/review-control-checkout.ts
git commit -m "test(iter2-c): manual review control scenario"
git push -u origin test/iter2-member-c-manual
gh pr create --title "[TEST] 迭代二 · 成员 C 手动验证" --body "手动验证 review/full review/summary/pause/resume/configuration。"
```

创建 PR 后，先等初始自动 review 完成。

---

## 2. 手动测试步骤

### C1. 验证 `@aireviewer` mention

在 PR Conversation 输入：

```text
@aireviewer help
```

期望：

- Bot 正常返回 help 表格。
- help 说明里包含 `@ai-reviewer`、`@codesentinel`、`@aireviewer`。

### C2. 验证 `summary`

在 PR Conversation 输入：

```text
@aireviewer summary
```

期望：

- 先出现 ACK：`正在执行 summary ...`。
- 最终回复包含 `PR 摘要已重新生成`。
- PR 摘要评论被更新。
- 不新增行级 review comments。

### C3. 验证 `review` 增量审查

先新建文件 `utils/review-control-incremental.ts`：

```ts
import type {ReviewControlCartLine} from './review-control-checkout'

export function mergeReviewControlDraft(
  serverLines: ReviewControlCartLine[],
  localLines: ReviewControlCartLine[]
): ReviewControlCartLine[] {
  const byId = new Map(serverLines.map(line => [line.id, line]))

  for (const localLine of localLines) {
    // 故意问题：无版本/更新时间判断，离线草稿可能覆盖服务端更新。
    byId.set(localLine.id, localLine)
  }

  return Array.from(byId.values())
}
```

提交并推送：

```bash
git add utils/review-control-incremental.ts
git commit -m "test(iter2-c): add incremental review change"
git push
```

然后在 PR Conversation 输入：

```text
@codesentinel review
```

期望：

- 最终回复包含 `增量审查已完成`。
- Actions 日志出现 `Will review from commit:`。
- 不再返回 `Command not implemented: review`。

### C4. 验证 `full review`

在 PR Conversation 输入：

```text
@aireviewer full review
```

期望：

- 最终回复包含 `全量审查已完成`。
- Actions 日志出现 `Will review full diff from the base commit:`。
- 不再返回 `Command not implemented: full review`。

### C5. 验证 `pause`

在 PR Conversation 输入：

```text
@aireviewer pause
```

期望：

- 最终回复包含 `已暂停当前 PR 的自动审查`。
- PR body 里出现隐藏状态块：

```text
<!-- codesentinel-review-state:start -->
state: paused
<!-- codesentinel-review-state:end -->
```

可用下面命令查看：

```bash
gh pr view <PR编号> --json body -q .body | sed -n '/codesentinel-review-state:start/,/codesentinel-review-state:end/p'
```

### C6. 验证 pause 后自动审查跳过

在 pause 后，新建文件 `utils/review-control-paused.ts`：

```ts
import type {ReviewControlCartLine} from './review-control-checkout'

export function restoreReviewControlSnapshot(rawSnapshot: string): ReviewControlCartLine[] {
  // 故意问题：直接信任 JSON.parse 结果，没有校验字段类型和范围。
  return JSON.parse(rawSnapshot) as ReviewControlCartLine[]
}
```

提交并推送：

```bash
git add utils/review-control-paused.ts
git commit -m "test(iter2-c): add paused auto-review gate change"
git push
```

期望：

- `pull_request synchronize` workflow 触发。
- Actions 日志包含 `Skipped: review automation is paused for this PR`。
- 不产生新的自动审查摘要或行级评论。

### C7. 验证 `configuration`

在 PR Conversation 输入：

```text
@aireviewer configuration
```

期望：

- 回复包含 `## 当前审查配置`。
- 表格里 `自动审查状态` 是 `paused`。
- 表格包含 `disable_review`、`max_files`、`openai_light_model`、`openai_heavy_model` 等配置。

### C8. 验证 `resume`

在 PR Conversation 输入：

```text
@aireviewer resume
```

期望：

- 最终回复包含 `已恢复当前 PR 的自动审查`。
- PR body 状态变为 `state: active`。

### C9. 验证手动 review 作为 webhook 丢失兜底

在 PR Conversation 输入：

```text
@codesentinel review
```

期望：

- 最终回复包含 `增量审查已完成`。
- Actions 日志不出现 `context.payload.pull_request is null`。
- 证明 `issue_comment` 手动触发能正确反查 PR 并执行审查。

---

## 3. 验收清单

| # | 场景 | 通过? | 备注 |
| :-: | :--- | :---: | :--- |
| C1 | `@aireviewer help` alias | | |
| C2 | `summary` 重新生成摘要 | | |
| C3 | `review` 增量审查 | | |
| C4 | `full review` 全量审查 | | |
| C5 | `pause` 写入 paused 状态 | | |
| C6 | paused 后自动审查跳过 | | |
| C7 | `configuration` 展示 paused 和配置 | | |
| C8 | `resume` 写入 active 状态 | | |
| C9 | issue_comment 手动 review 兜底 | | |
