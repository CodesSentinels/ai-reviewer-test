# 命令框架核对表（人工验证）

> 每完成一个用例，勾选左侧 checkbox。不通过的用例在"实际"列填写结果。

PR 环境信息：
- 仓库: `CodesSentinels/ai-reviewer-test`
- 测试分支: `test/iter2-member-a`
- PR 编号: `____`
- 验证人: `____`
- 验证日期: `____`

---

## 基础路径

- [ ] **T01 — help (ai-reviewer 别名)**
  - 输入: `@ai-reviewer help`
  - 事件: `issue_comment`
  - 期望: Bot 回复包含 "支持的命令" 表格，列出 8 条命令
  - 实际: ______

- [ ] **T02 — help (codesentinel 别名)**
  - 输入: `@codesentinel help`
  - 期望: 与 T01 相同
  - 实际: ______

- [ ] **T03 — 大小写不敏感**
  - 输入: `@AI-Reviewer HELP`
  - 期望: 与 T01 相同
  - 实际: ______

- [ ] **T04 — 复合命令识别**
  - 输入: `@ai-reviewer full review`
  - 期望: Bot 回复 `NOT_IMPLEMENTED`；消息包含 `full review`（不是 `full`）
  - 实际: ______

- [ ] **T05 — 参数 kv 解析**
  - 输入: `@ai-reviewer review files=src/foo.ts`
  - 期望: 透传到 review stub，响应 `NOT_IMPLEMENTED`
  - 实际: ______

---

## 安全与防护

- [ ] **T06 — shell 元字符注入**
  - 输入: `@ai-reviewer review $(whoami)`
  - 期望: `INVALID_ARGS`，消息明确提到非法字符
  - 实际: ______

- [ ] **T07 — 反引号注入**
  - 输入: `` @ai-reviewer review `ls` ``
  - 期望: `INVALID_ARGS`
  - 实际: ______

- [ ] **T08 — 非法字符集（中文参数）**
  - 输入: `@ai-reviewer review 请审`
  - 期望: `INVALID_ARGS`
  - 实际: ______

- [ ] **T09 — 命令行超长**
  - 输入: `@ai-reviewer review ` + 520 个 `a`
  - 期望: `INVALID_ARGS`（命令长度超上限）
  - 实际: ______

- [ ] **T10 — 参数个数超上限**
  - 输入: `@ai-reviewer review a b c d e f g h i j k l m n o p q`（17 个参数）
  - 期望: `INVALID_ARGS`
  - 实际: ______

---

## 权限

- [ ] **T11 — read 权限不能 pause**
  - 账号: read 权限
  - 输入: `@ai-reviewer pause`
  - 期望: `FORBIDDEN`
  - 实际: ______

- [ ] **T12 — PR 作者豁免 review**
  - 账号: PR 作者（read 权限即可）
  - 输入: `@ai-reviewer review`
  - 期望: 通过权限 → 命中 stub → `NOT_IMPLEMENTED`
  - 实际: ______

- [ ] **T13 — PR 作者豁免不扩展到 pause**
  - 账号: PR 作者（read 权限）
  - 输入: `@ai-reviewer pause`
  - 期望: `FORBIDDEN`
  - 实际: ______

---

## 幂等与时序

- [ ] **T14 — ACK 先于结果出现**
  - 输入: `@ai-reviewer resolve`
  - 期望: 1) 先看到 ⏳ ACK 评论；2) 随后同一条评论被编辑为最终结果（NOT_IMPLEMENTED）
  - 实际: ______

- [ ] **T15 — 幂等: 重复触发不二次回复**
  - 步骤: 执行 T01 → 手动 re-run workflow（同一条触发评论）
  - 期望: 第二次不产生新的 help 回复
  - 实际: ______

---

## 事件路径

- [ ] **T16 — issue_comment 路径**
  - 在 PR 顶部评论区（Conversation tab）贴 `@ai-reviewer help`
  - 期望: 正常响应
  - 实际: ______

- [ ] **T17 — pull_request_review_comment 路径**
  - 在 PR Files changed tab 某行上贴 review comment: `@ai-reviewer help`
  - 期望: 正常响应
  - 实际: ______

---

## Fallback

- [ ] **T18 — 对话 fallback**
  - 输入: `@ai-reviewer 这里为什么用 forEach 而不是 map？`
  - 期望: 命中 conversation 分支（由现有 review-comment.ts 处理），Bot 给出对话式回复
  - 实际: ______

- [ ] **T19 — 完全忽略**
  - 输入: `看起来不错` (无 @bot)
  - 期望: 无任何回复
  - 实际: ______

- [ ] **T20 — bot 自评论循环**
  - 观察: Bot 自己发出的评论不会触发新一轮命令处理
  - 期望: workflow 日志中 `commentEvent dispatcher outcome: {"kind":"ignored","reason":"comment from bot"}`
  - 实际: ______

---

## 验收标准

- **P0**: T01–T10、T14、T16、T17、T18、T19、T20 全部通过
- **P1**: T11–T13、T15 通过
- **P2**: （暂无，B/C/D 接入后补充）
