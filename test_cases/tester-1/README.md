# Tester 1 — 核心审查流程测试指南

本指南面向**未直接参与开发、希望快速体验 AI Reviewer 功能**的测试人员。

---

## 背景：这个 Bot 做什么？

AI Reviewer 是一个 GitHub Action，当有人开 PR 时自动触发，使用 AI 模型对代码进行审查，产出：

1. **PR 顶部摘要评论** — Walkthrough（改了什么）+ Changes 表格 + 发布说明
2. **行级评论** — 精确到具体代码行的问题指出（安全漏洞、逻辑错误、代码质量等）
3. **跨文件影响分析** — 如果你改的函数被其他文件引用，Bot 会告诉你哪些文件受影响

Bot 的名字叫 **codesentinel-review-bot**，所有交互命令前缀为 `@codesentinel`。

---

## 前置准备

### 1. 确认仓库访问权限

测试在这个仓库进行：https://github.com/CodesSentinels/ai-reviewer-test

需要有该仓库的 **write 权限**（用于推送分支和创建 PR）。

### 2. 本地环境

```bash
# 克隆测试仓库（如果还没有的话）
git clone https://github.com/CodesSentinels/ai-reviewer-test.git
cd ai-reviewer-test

# 确认 .secrets 文件存在（内含 GITHUB_TOKEN）
cat .secrets   # 应输出 GITHUB_TOKEN=ghp_...
```

> `.secrets` 已在本地配置好，`gh` CLI 和脚本都会自动读取，无需手动操作。

### 3. 确认 gh CLI 可用

```bash
cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
GH_TOKEN=$(grep '^GITHUB_TOKEN=' .secrets | cut -d= -f2) gh auth status
# 应显示: Logged in to github.com as ...
```

---

## 测试场景与脚本

所有脚本在 `test_cases/tester-1/` 目录下，均从 `test/dev4` 拉出新分支，PR 也 target 回 `test/dev4`，**不影响 main**。

| 脚本 | 覆盖用例 | 核心验证点 |
|------|---------|-----------|
| `setup-1.1-basic-review.sh` | 1.1.1 ~ 1.1.4 | 自动触发审查、摘要格式、行级评论、发布说明 |
| `setup-1.1-ignore.sh` | 1.1.6 | `@codesentinel: ignore` 跳过全部审查 |
| `setup-1.2-incremental.sh` | 1.2 第一步 | 创建 PR，推送 Commit A |
| `push-1.2-commit-b.sh` | 1.2.1 ~ 1.2.3 | 推送 Commit B（等首次审查完再执行） |
| `setup-1.3-cross-file-deps.sh` | 1.3.1 ~ 1.3.3 | 跨文件依赖：Bot 发现 PR 外的引用方 |
| `setup-1.4-file-filters.sh` | 1.4.1 / 1.4.2 / 1.4.4 | 二进制 / CSS / lock 文件不被审查 |
| `setup-1.4-max-files.sh` | 1.4.3 | max_files 上限截断（需改 workflow 配置） |

---

## 推荐体验顺序

### Step 1 — 基础审查（最直观，先从这里开始）

```bash
cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
bash test_cases/tester-1/setup-1.1-basic-review.sh
```

脚本会：
- 从 `test/dev4` 拉出新分支
- 提交一个含 SQL 注入 / eval / 未 await 等典型问题的文件
- 自动创建 PR，输出 PR 链接

**等待 1~3 分钟**，打开输出的 PR 链接，检查：

| 验证点 | 在哪里看 |
|--------|---------|
| 1.1.1 Bot 自动评论 | PR 的 Conversation 标签页 |
| 1.1.2 摘要含 Walkthrough + 变更表格 | Bot 发的第一条评论 |
| 1.1.3 行级评论定位准确 | PR 的 Files changed 标签页，评论出现在对应代码行旁 |
| 1.1.4 PR 描述末尾有发布说明 | PR 描述底部，含 `Summary by CodeSentinel` |

---

### Step 2 — ignore 跳过（验证控制能力）

```bash
bash test_cases/tester-1/setup-1.1-ignore.sh
```

PR body 中包含 `@codesentinel: ignore`，Bot 应**完全沉默**，不产出任何评论。

**等 Actions 运行完成后**，打开 PR 确认无任何 Bot 评论。
Actions 日志路径：PR 页面 → Checks 标签 → `Code Review` → 展开步骤日志。

---

### Step 3 — 跨文件依赖分析（核心特色功能）

```bash
bash test_cases/tester-1/setup-1.3-cross-file-deps.sh
```

这个场景最能体现 Bot 的能力：

**PR 里只修改了两个文件**：
- `utils/formatPrice.ts` — 参数签名破坏性变更（新增必填参数）
- `composables/useCart.ts` — 返回类型变更

**但仓库里还有三个文件引用了它们**（未在 PR 中出现）：
- `components/ProductCard.vue` — 显式 `import { formatPrice }`
- `components/CartSummary.vue` — Nuxt auto-import `useCart`
- `pages/cart.vue` — Nuxt auto-import `useCart`

Bot 应该通过依赖分析发现这些引用方，并在评论中提醒它们受影响。

**验证方式**：查看 Bot 的摘要评论或行级评论，是否提及 `ProductCard.vue`、`CartSummary.vue`、`cart.vue`。

---

### Step 4 — 增量审查（两步操作）

```bash
# 第一步：创建 PR，推送 Commit A（简单加法/乘法函数）
bash test_cases/tester-1/setup-1.2-incremental.sh
```

等待 Bot 完成**首次审查**（1~3 分钟），然后：

```bash
# 第二步：推送 Commit B（新增除零 / 负指数问题的函数）
bash test_cases/tester-1/push-1.2-commit-b.sh
```

**验证点**：
- Bot 第二次评论只涉及 `divide` / `power` 函数，不重复提及 `add` / `multiply`
- 查看 Bot 摘要评论的 HTML 源码（浏览器右键查看元素），找到 `commit_ids_reviewed` 隐藏区块，确认包含两个 commit 的 SHA

**验证 full review**：在 PR 评论区直接输入：
```
@codesentinel full review
```
Bot 会从 PR 基准重新全量审查。

---

### Step 5 — 文件过滤

```bash
bash test_cases/tester-1/setup-1.4-file-filters.sh
```

PR 同时包含 4 种文件：
- `utils/filter-test.ts` — 应被审查
- `assets/ignored.css` — path_filters 不含 .css，应跳过
- `assets/test-icon.png` — 二进制文件，应跳过
- `pnpm-lock.yaml` — lock 文件，应跳过

验证 Bot 评论中**只涉及 `.ts` 文件**。

---

## 如何查看 Bot 是否真的分析了跨文件依赖

打开 PR 对应的 Actions 运行日志：
1. PR 页面 → 顶部 **Checks** 标签 → `Code Review`
2. 展开 `Run CodesSentinels/ai-reviewer` 步骤
3. 搜索关键词：
   - `dependency analysis` — 看依赖分析各步骤日志
   - `step 1.5` — 看哪些文件被过滤掉
   - `step 2` / `step 5` — 看发现了哪些引用关系
   - `noise-control` — 看评论去重/截断情况

---

## 常用命令（在 PR 评论区发送）

| 命令 | 作用 |
|------|------|
| `@codesentinel full review` | 强制全量重新审查（忽略增量标记） |
| `@codesentinel pause` | 暂停后续自动审查 |
| `@codesentinel resume` | 恢复自动审查 |
| `@codesentinel resolve` | 将 Bot 的评论标记为已解决 |

---

## 注意事项

- **所有 PR 都 target `test/dev4`**，不会影响 main 分支
- Bot 使用 `gpt-5.4-mini` 模型，审查质量和速度取决于 OpenAI API 响应
- 1.4.3（max_files）和 1.1.5（disable_review）需要手动修改 `.github/workflows/ai-reviewer.yml`，改完记得还原
- 如果 Actions 没有触发，检查分支名是否满足 `test/dev*` 规则
