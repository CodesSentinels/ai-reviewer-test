# 幂等验证的"反向"期望

幂等场景下**不会**有新的评论。正确行为是：

1. 第一次发出命令 `@ai-reviewer help` → Bot 正常回复，评论内置 HTML tag
   `<!-- codesentinel-cmd-reply:{commentId}:help -->`
2. 通过 re-run workflow 或其他方式让同一条触发评论再次被 webhook 投递
3. 调度器扫描 PR issue comments，发现已存在 `codesentinel-cmd-reply:{commentId}:help` → 视为已处理
4. **不发布任何新的回复**

在 workflow 日志中应看到：

```
command dispatcher: skip duplicate commentId={commentId} cmd=help
commentEvent dispatcher outcome: {"kind":"executed","command":"help","ok":false,"error":"DUPLICATE"}
```
