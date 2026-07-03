# Tester 3 — 对话交互与质量控制测试指南

本指南面向**验证对话追问、噪音控制、Lint/SAST 集成、评论去重、Web 搜索/Shell 执行**功能的测试人员。

---

## 背景：测试什么？

测试人 3 负责验证 AI Reviewer 的"质量控制"层面能力：

1. **对话追问 (3.1/3.2)** — 在行级评论 thread 中追问 Bot，验证多轮上下文和轮次限制
2. **噪音控制 (3.3)** — 评论有严重级别标签、排序、截断、合并
3. **Lint/SAST 集成 (3.4)** — ESLint / tsc / Biome / Semgrep 结果注入 AI 评论
4. **评论去重 (3.5)** — 同类 lint finding 合并、不同类保留独立
5. **Web 搜索 + Shell (3.6)** — Bot 联网查文档、执行 shell 检查版本

---

## 前置准备

与 Tester 1 相同，请确认：

```bash
cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
cat .secrets   # 确认 GITHUB_TOKEN 存在
GH_TOKEN=$(grep '^GITHUB_TOKEN=' .secrets | cut -d= -f2) gh auth status
```

---

## 测试脚本一览

| 脚本 | 覆盖用例 | 核心验证点 |
|------|---------|-----------|
| `setup-3.3-noise-control.sh` | 3.3.1~3.3.5 / 3.4.1~3.4.4 / 3.5.1~3.5.3 | 噪音控制 + Lint + 去重（主场景） |
| `test-3.1-conversation.sh` | 3.1.1~3.1.6 | 对话追问操作指南 |
| `test-3.2-turn-limit.sh` | 3.2.1~3.2.4 | 轮次限制操作指南 |
| `setup-3.4-semgrep.sh` | 3.4.7 | Semgrep SAST 安全扫描 |
| `setup-3.4-lint-disabled.sh` | 3.4.5 / 3.4.6 | Lint 开关关闭验证 |
| `setup-3.6-web-search.sh` | 3.6.1 / 3.6.2 | Web 搜索 + Shell 触发 |
| `setup-3.6-disabled.sh` | 3.6.3 / 3.6.4 | Web 搜索 + Shell 关闭验证 |
| `setup-3.3-max-comments-zero.sh` | 3.3.6 | max_review_comments=0 不截断 |

---

## 推荐测试顺序

### Step 1 — 主场景（噪音控制 + Lint + 去重）

```bash
cd /Users/anton/Developer/CodesSentinels/ai-reviewer-test
bash test_cases/tester-3/setup-3.3-noise-control.sh
```

这是最核心的测试，一个 PR 覆盖 3.3 / 3.4 / 3.5 大部分用例。等待 Bot 审查完成后检查：

| 验证点 | 在哪里看 |
|--------|---------|
| 3.3.1 级别徽标 | 行级评论顶部 emoji |
| 3.3.2 级别排序 | critical 评论在前，nit 在后 |
| 3.3.5 同类合并 | 5 个 Math.random 合并为 1~2 条 |
| 3.4.1~3.4.3 lint 引用 | 评论中出现规则名/错误码 |
| 3.4.4 Tools 卡片 | 评论底部 🧰 Tools 段落 |
| 3.5.1~3.5.3 去重 | 5 行 var 合并为 1 条 |

---

### Step 2 — 对话追问（依赖 Step 1 的行级评论）

```bash
bash test_cases/tester-3/test-3.1-conversation.sh
```

脚本会打印操作指南。需要在 GitHub PR 页面手动操作：
- 在 Bot 行级评论 thread 中发 `@codesentinel ...` 追问
- 验证 Bot 回复的质量和上下文关联

---

### Step 3 — 轮次限制

```bash
bash test_cases/tester-3/test-3.2-turn-limit.sh
```

在同一 thread 连续追问 11 次，验证第 11 轮被拒。

---

### Step 4 — Semgrep SAST（需 enable_semgrep: true）

```bash
bash test_cases/tester-3/setup-3.4-semgrep.sh
```

---

### Step 5 — Web 搜索 + Shell

```bash
bash test_cases/tester-3/setup-3.6-web-search.sh
```

---

### Step 6 — 配置切换测试（需改 workflow 后恢复）

这些测试需要临时修改 `.github/workflows/ai-reviewer.yml`，**测试后记得恢复**：

```bash
# 3.3.6 不截断
bash test_cases/tester-3/setup-3.3-max-comments-zero.sh

# 3.4.5 / 3.4.6 关闭 lint
bash test_cases/tester-3/setup-3.4-lint-disabled.sh

# 3.6.3 / 3.6.4 关闭 web search / shell
bash test_cases/tester-3/setup-3.6-disabled.sh
```

---

## 如何查看 Actions 日志

1. 打开 PR 页面 → 顶部 **Checks** 标签 → `Code Review`
2. 展开 `Run CodesSentinels/ai-reviewer` 步骤
3. 搜索关键词：
   - `[web_search_debug]` — Web 搜索调用日志
   - `[shell_debug]` — Shell 执行日志
   - `semgrep` — Semgrep 扫描结果
   - `lint` — Lint 工具执行状态
   - `noise-control` — 评论截断/合并日志
   - `dedup` — 去重日志

---

## 注意事项

1. **测试顺序很重要**：3.1/3.2 依赖 Bot 先产出行级评论，务必先执行 Step 1
2. **配置切换测试**：3.3.6 / 3.4.5 / 3.4.6 / 3.6.3 / 3.6.4 修改 workflow 后必须恢复
3. **所有 PR target `test/dev4`**，不影响 main
4. **对话测试耗时长**：3.2.1 需要连续 11 轮追问，每轮等 Bot 回复
5. **Semgrep 需额外启用**：默认可能未开启 `enable_semgrep`
