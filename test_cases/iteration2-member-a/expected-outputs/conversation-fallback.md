# 对话 fallback 期望

输入: `@ai-reviewer 这里为什么用 forEach 而不是 map？`

**解析阶段**: 命中 `@ai-reviewer` 但首个 token `这里` 不在命令白名单 → `ParseOutcome.kind = "conversation"`

**调度阶段**: `dispatchCommentEvent` 返回 `{kind: "fallback_conversation"}`

**后续处理**: `command-handler.ts` 检测事件类型：
- 如果是 `pull_request_review_comment`（即在 PR Files changed tab 的行内评论）→ 调用现有的 `handleReviewComment`，由 heavy bot 生成一条对话式回复
- 如果是 `issue_comment`（PR 顶部评论区）→ 本迭代暂不支持，workflow 日志打印:
  ```
  commentEvent: conversation fallback skipped (issue_comment 对话由后续迭代支持)
  ```

**验证点**:
- 命令框架**没有**在回复中写入命令 reply tag（`codesentinel-cmd-reply:...`）
- 如果是 review comment 事件，看到 bot 的自由格式回复（由成员 D 后续用命令化的对话 handler 替换）
