<!-- codesentinel-cmd-reply:{commentId}:help -->
🤖 AI Reviewer · `help`

## 支持的命令

| 命令 | 描述 | 最低权限 |
| :--- | :--- | :------- |
| `@ai-reviewer review` | 触发增量审查（仅审查自上次审查以来的新增变更） | `write` |
| `@ai-reviewer full review` | 触发全量审查（从 base 到 HEAD 的完整 diff） | `write` |
| `@ai-reviewer resolve` | 批量将所有 CodeSentinel 审查意见标记为已解决 | `write` |
| `@ai-reviewer summary` | 基于当前最新代码重新生成 PR 摘要 | `write` |
| `@ai-reviewer pause` | 暂停对当前 PR 的自动审查 | `write` |
| `@ai-reviewer resume` | 恢复对当前 PR 的自动审查 | `write` |
| `@ai-reviewer configuration` | 显示当前仓库的审查配置 | `read` |
| `@ai-reviewer help` | 显示所有支持的命令及用法 | `read` |

> 🤖 Bot 同时支持 `@ai-reviewer` 与 `@codesentinel` 两个 mention。
