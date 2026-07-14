# 域 A 基础审查 —— PR 描述模板

将以下内容作为 PR 描述，用于验证发布说明写回（A4）：

---
本 PR 引入一个包含多类问题的请求处理函数，用于验证 AI Reviewer 的基础审查能力。

预期 Bot 会：
- 产出顶部摘要评论（Walkthrough + Changes 表格）
- 对 SQL 注入 / eval / 未 await / 循环内正则产出行级评论
- 在 PR 描述末尾追加 "Summary by CodeSentinel" 发布说明
---
