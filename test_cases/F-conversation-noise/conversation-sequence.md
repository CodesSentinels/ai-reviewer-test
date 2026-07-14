# 域 F 对话追问序列（在 processPayment 的行级评论 thread 中执行）

> 常量：MAX_CONVERSATION_TURNS=10，MAX_CHAIN_CHARS=12000
> 仅 pull_request_review_comment（行级 thread）支持对话；issue_comment 不支持

## F-对话（3.1 / 3.2）
1. `@codesentinel 为什么直接拼接 SQL 是个问题？可以说说攻击场景吗？` → 引用该行 + 解释
2. `@codesentinel 用参数化查询的话这段应该怎么改？`                  → 含修改建议，引用上一轮
3. (在 thread 中直接回复，不含 @) → Bot 不触发
4. (观察 Bot 回帖后无新 workflow run) → 无自触发循环
5. 循环追问至第 11 轮 → 第 11 轮提示「轮次已达上限」
6. 在 PR 主评论区（非行级）`@codesentinel 解释一下` → Bot 不回复（issue_comment 不支持对话）
