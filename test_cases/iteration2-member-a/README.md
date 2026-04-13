# 迭代二 · 成员 A · 集成测试用例

> **对应功能**: 命令框架（平台与命令框架，入口层）
> **技术设计**: [../../docs/04-iteration-02-member-a-design.md](../../../ai-reviewer/docs/04-iteration-02-member-a-design.md)
> **负责模块**: Webhook 接入、命令解析、权限校验、路由分发、`help`、错误处理、命令注入防护、响应时延保障

本目录收录的是**在真实 GitHub PR 上可手工执行**的端到端验证用例。单元测试位于 `ai-reviewer/__tests__/command-*.test.ts`，本目录的作用是覆盖单元测试无法触达的路径：真实 webhook 投递、真实 GitHub API、真实 Actions 冷启动。

---

## 0. 前置条件

1. 已在 `CodesSentinels/ai-reviewer-test` 仓库开启 Actions 并配置 `OPENAI_API_KEY` secret。
2. 已将 `.github/workflows/ai-reviewer.yml` 更新为支持 `issue_comment` 触发器（本目录已提供补丁，见 `workflow-patch.yml`）。
3. 测试分支已基于 `main` 创建，例如 `test/iter2-member-a`。
4. 在该分支上创建一个 PR（可引用任意一个本仓库里已有的小改动触发 PR review）。

---

## 1. 目录结构

```
test_cases/iteration2-member-a/
├── README.md                  ← 本文件：测试指南与用例清单
├── COMMANDS.md                ← 逐命令期望行为矩阵（可打印核对表）
├── workflow-patch.yml         ← .github/workflows/ai-reviewer.yml 的建议补丁
├── run-manual-test.sh         ← 半自动脚本：通过 gh CLI 依次贴出命令评论
├── trigger-change.ts          ← 一个故意的微小 TS 改动文件，用于触发 PR
└── expected-outputs/          ← 每条命令的期望响应 Markdown 快照
    ├── help.md
    ├── unknown-command.md
    ├── invalid-args.md
    ├── forbidden.md
    ├── review-not-implemented.md
    ├── resolve-not-implemented.md
    ├── full-review-not-implemented.md
    ├── pause-not-implemented.md
    ├── conversation-fallback.md
    └── duplicate.md
```

---

## 2. 用例矩阵

| # | 场景 | 输入评论 | 期望结果（现阶段，仅成员 A 交付） | 验证点 |
| :-: | :--- | :------- | :-------------------------------- | :----- |
| 1 | help 正常响应 | `@ai-reviewer help` | Bot 回复包含 "支持的命令" 的 Markdown 表格，列出 8 条命令 | 注册表聚合 / help handler |
| 2 | bot 别名支持 | `@codesentinel help` | 同上 | 多别名 parser |
| 3 | 大小写 | `@AI-Reviewer HELP` | 同上 | 大小写不敏感 |
| 4 | 复合命令识别 | `@ai-reviewer full review` | Bot 回复 NOT_IMPLEMENTED（因 C 尚未接入） | 最长前缀匹配 |
| 5 | 参数 kv | `@ai-reviewer review files=src/foo.ts` | NOT_IMPLEMENTED（参数被解析但未被消费） | 参数解析 |
| 6 | 未知命令 | `@ai-reviewer reboot` | fallback 为对话模式（原 review-comment 对话逻辑） | 未命中走 conversation |
| 7 | 非法参数 - shell 注入 | `@ai-reviewer review $(whoami)` | Bot 回复 **INVALID_ARGS**，明确指出非法字符 | 注入防护 |
| 8 | 非法参数 - 中文 | `@ai-reviewer review 请审` | Bot 回复 **INVALID_ARGS** | 字符集白名单 |
| 9 | 命令行超长 | `@ai-reviewer review aaaa...(>512)` | Bot 回复 **INVALID_ARGS** | 长度上限 |
| 10 | 权限不足 | 用 read 权限账号评论 `@ai-reviewer pause` | Bot 回复 **FORBIDDEN** | 权限校验 |
| 11 | PR 作者豁免 | PR 作者（read 权限）评论 `@ai-reviewer review` | 进入 handler（NOT_IMPLEMENTED，不被权限拦截） | 作者豁免 |
| 12 | 幂等 | 连续两次贴同样评论 `@ai-reviewer help` | 第一次正常、第二次命令回复中显示 **DUPLICATE**（或仅第一次成功回复） | 幂等 tag |
| 13 | 对话 fallback | `@ai-reviewer 这里为啥用 forEach？` | 走原有对话逻辑（heavy bot 回复） | conversation 分支 |
| 14 | bot 自评论忽略 | 在任意 Bot 发出的评论上再收到 webhook | 无反应（dispatcher 提前 ignored） | Bot 过滤 |
| 15 | 5s ACK | 执行 stub 命令 `@ai-reviewer resolve` | ≤ 5 秒内 PR 页面出现 ⏳ ACK 评论；之后更新为 NOT_IMPLEMENTED | ACK 时序 |
| 16 | issue_comment 事件 | 在 PR 顶部评论区（非 review thread）发送 `@ai-reviewer help` | Bot 回复 help | issue_comment 路径 |
| 17 | review_comment 事件 | 在 PR diff 行评论发送 `@ai-reviewer help` | Bot 回复 help | pull_request_review_comment 路径 |

现阶段 B/C/D 尚未接入真实 handler，所有 stub 命令（`review` / `full review` / `resolve` / `summary` / `pause` / `resume` / `configuration`）均应返回 `NOT_IMPLEMENTED`。当 B/C/D 完成后，本表对应行的"期望结果"应同步更新。

---

## 3. 执行步骤

### 3.1 准备 workflow

```bash
# 在 ai-reviewer-test 仓库根目录
cp test_cases/iteration2-member-a/workflow-patch.yml .github/workflows/ai-reviewer.yml
git add .github/workflows/ai-reviewer.yml
git commit -m "test: enable issue_comment trigger for iter2 member A"
git push
```

补丁相对 `.github/workflows/ai-reviewer.yml` 的变化：

- 新增 `issue_comment: types: [created]` 触发器
- 调整 concurrency group 以便支持 issue_comment 并发

### 3.2 创建测试 PR

```bash
git checkout -b test/iter2-member-a
cp test_cases/iteration2-member-a/trigger-change.ts utils/iter2-marker.ts
git add utils/iter2-marker.ts
git commit -m "test: trigger PR for iter2 member A"
git push -u origin test/iter2-member-a
gh pr create --title "[TEST] iter2 member A command framework" \
  --body "用于验证命令框架的测试 PR"
```

### 3.3 运行用例

两种方式任选：

**方式 A：手工核对表**
- 打开 [COMMANDS.md](COMMANDS.md)，按顺序手动贴评论，逐条勾选期望行为。

**方式 B：半自动脚本**
```bash
PR_NUMBER=<your-pr-number> ./test_cases/iteration2-member-a/run-manual-test.sh
```
脚本使用 `gh` CLI 依次贴出每条用例评论，用例之间睡眠 30 秒（等待 Bot 回复），并在最后输出 PR 评论列表供人工核对。

### 3.4 清理

```bash
gh pr close --delete-branch <pr-number>
```

---

## 4. 已知限制 & 回归事项

- **Actions 冷启动** 约 6–10 秒，因此用例 15 的 "5s ACK" 实际 P95 约 4–8s。验收通过的口径：**ACK 评论必须在结果评论之前可见**，不再严格卡秒数。
- 幂等用例 12 依赖 `hasBeenProcessed` 扫描最新 100 条 issue comments；若测试 PR 已有大量评论噪音，需要新建干净 PR。
- 权限相关用例 10/11 需要至少两个测试账号（write 与 read）。若仅有单账号，可在仓库设置中临时切换协作者权限。
- 目前 `pause` 命令尚未由 C 接入，因此自动审查暂停路径只能在 C 完成后一起回归。

---

## 5. 迭代中的扩展点

当 B/C/D 陆续完成后：
- 修改本 README 的"期望结果"列，把 `NOT_IMPLEMENTED` 替换为真实响应
- 在 `expected-outputs/` 中新增真实快照
- `run-manual-test.sh` 中新增状态检查（例如 `@ai-reviewer resolve` 后通过 GraphQL 查 review thread 的 `isResolved` 字段）
