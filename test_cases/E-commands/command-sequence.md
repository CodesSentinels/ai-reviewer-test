# 域 E 命令测试序列（在 PR 评论区依次执行）

> 已注册命令：help / resolve / review / full review / summary / pause / resume / configuration
> mention 别名：@codesentinel 与 @ai-reviewer（均大小写不敏感）
> 权限：多数命令 minPermission=write；help 与 configuration 为 read

## E1 解析与路由（P0）
1. `@codesentinel help`              → 回帖展示所有命令用法
2. `@ai-reviewer help`               → 别名同样触发（E1 别名）
3. `@CodeSentinel HELP`              → 大小写不敏感，同样触发
4. `@codesentinel xyz`               → 回帖提示无效命令（UNKNOWN_COMMAND）
5. `这是一条普通评论，不含 mention`   → Bot 无任何响应
6. (观察) Bot 自身回帖后无二次触发（无死循环）

## E2 权限与限流（P0）
7. write 权限用户 `@codesentinel review`        → 执行成功
8. read 权限用户 `@codesentinel review`         → 回帖 FORBIDDEN
9. read 权限用户 `@codesentinel configuration`  → 执行成功（minPermission=read）
10. 快速连发 5+ 次 `@codesentinel help`          → 第 N 次被限流，提示重试时间
11. (通过 Actions 重跑同一条评论) 观察第二次判为 DUPLICATE（幂等）

## E3 resolve（P0）
12. 等 command-anchor.ts 的行级评论产出后 `@codesentinel resolve` → 批量 resolve + 统计
13. 在无待解决评论的 PR 上 `@codesentinel resolve`               → 回帖「没有找到待解决的审查意见」

## E4 审查控制（P0/P1）
14. `@codesentinel review`         → 触发增量审查
15. `@codesentinel full review`    → 从 base 全量审查
16. `@codesentinel summary`        → 重新生成顶部摘要
17. `@codesentinel pause`          → PR 写入暂停标记
18. (pause 后 push 新 commit)      → 不自动触发审查
19. `@codesentinel resume`         → 恢复标记
20. (resume 后 push 新 commit)     → 触发审查
21. `@codesentinel configuration`  → 展示当前配置表格

## E5 ACK 与反馈（P1）
22. 发送任意有效命令 → 评论上出现 🚀 表情（command_ack_reaction）
23. 执行 review → 先回「正在执行」，完成后更新
24. 触发错误场景 → 错误信息清晰、含操作建议
