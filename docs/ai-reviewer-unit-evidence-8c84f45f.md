# ai-reviewer 锁定 SHA 单元测试证据

- 被测版本：`CodesSentinels/ai-reviewer` develop，SHA `8c84f45fab547821ecefbf56aabbf215eb9d7dbf`
- 取证时间：2026-10-09
- 取证方式：把 ai-reviewer 在该 SHA 克隆到临时目录（不修改源仓库、不提交），`npm ci --ignore-scripts` 后运行相关测试文件：

```bash
npx jest __tests__/github-only.test.ts __tests__/characterization __tests__/command-permission-matrix.test.ts \
  __tests__/command-permission.test.ts __tests__/resolve.test.ts __tests__/github-write-idempotency.test.ts \
  __tests__/state-idempotency-retry.test.ts __tests__/git-platform.test.ts __tests__/commenter.test.ts \
  __tests__/review-line-comments.test.ts __tests__/sanitize-model-output.test.ts
```

- 结果：13 个测试套件、311 个用例全部通过，0 失败。
- 说明：这是 ai-reviewer 自带单测的结果，用来证明“需故障注入 / 进程级异常”的用例在代码层面有对应保护；它不替代真实环境验证，对应 FT 的备注里会写明覆盖范围。

## 通过判定的用例（PASS，coverage=unit-evidence / needs-injection）

### FT-229 uncaughtException 导致任务失败

- `characterization/main.characterization.test.ts` — main.ts run() — 改造前事件分发行为基线 uncaughtException → setFailed（不再只是 warning，避免假成功） — **passed**

### FT-230 unhandledRejection 导致任务失败

- `characterization/main.characterization.test.ts` — main.ts run() — 改造前事件分发行为基线 unhandledRejection → setFailed（不再只是 warning，避免假成功） — **passed**

### FT-062 异常以失败状态退出

- `characterization/main.characterization.test.ts` — main.ts run() — 改造前事件分发行为基线 ConfigError（非法配置）→ setFailed，不调用模型（ARCH-010 fail closed） — **passed**
- `characterization/main.characterization.test.ts` — main.ts run() — 改造前事件分发行为基线 uncaughtException → setFailed（不再只是 warning，避免假成功） — **passed**
- `characterization/main.characterization.test.ts` — main.ts run() — 改造前事件分发行为基线 unhandledRejection → setFailed（不再只是 warning，避免假成功） — **passed**
- `characterization/main.characterization.test.ts` — main.ts run() — 改造前事件分发行为基线 pull_request 事件但 payload 缺少 pull_request 字段 → fail closed（setFailed，不调用模型） — **passed**

### FT-150 权限查询失败时 fail closed（命令路径）

- `command-permission-matrix.test.ts` — CMD-016: 权限查询失败一律 fail closed 查询失败时所有命令都被拒绝——包括作者豁免集内的命令 — **passed**
- `command-permission-matrix.test.ts` — CMD-016: 权限查询失败一律 fail closed API 抛错 → 权限为 none — **passed**
- `command-permission-matrix.test.ts` — CMD-016: 权限查询失败一律 fail closed 查询失败与「确认为 none」必须可区分（否则无法 fail closed） — **passed**

### FT-061 部分评论失败时状态可解释（resolve 部分失败）

- `resolve.test.ts` — resolveHandler.execute 部分失败（adapter 返回 failed>0 而非 throw）→ 返回 "⚠️" 降级消息 — **passed**
- `resolve.test.ts` — batchResolve 错误输出 权限错误 → warning 只输出一次，含 resolve_token 指引 — **passed**

### FT-226 GitHub API 暂时失败时重试

- `github-write-idempotency.test.ts` — 超时重试不产生重复评论 始终失败 → 有限次后抛出，不无限重试 — **passed**
- `github-write-idempotency.test.ts` — 超时重试不产生重复评论 对照组：服务端确实没写成功 → 探测落空，正常重试 — **passed**
- `github-write-idempotency.test.ts` — 写前埋 marker 关掉 octokit 自动重试（否则它会在我们看不见的地方重发 POST） — **passed**

### FT-228 部分评论失败不破坏全部结果

- `review-line-comments.test.ts` — REVIEW-014：行号映射失败时降级到顶层评论 部分成功部分失败 → 只把失败的那条降级 — **passed**
- `review-line-comments.test.ts` — 部分提交失败时的清理与降级（GitLab 逐条提交的形态） 部分失败 → 失败项走统一顶层降级，不静默丢弃 — **passed**
- `review-line-comments.test.ts` — REVIEW-014：行号映射失败时降级到顶层评论 顶层降级也失败 → 如实报告彻底丢失，并把内容写进日志 — **passed**

### FT-040 非法模型输出安全处理（行号不在 diff / 引用乱码）

- `review-line-comments.test.ts` — REVIEW-014：行号映射失败时降级到顶层评论 逐条也发不出去 → 内容进顶层评论，不静默丢弃 — **passed**
- `sanitize-model-output.test.ts` — sanitizeModelOutput — 裸文本引用标记 剥离用户实际遇到的乱码（citeturn0search0） — **passed**
- `sanitize-model-output.test.ts` — sanitizeModelOutput — 分隔符包裹形式（PUA / Block Elements） 剥离孤立分隔符字符（包裹不完整时的兜底） — **passed**

## 不适用或无证据的用例（N/A）

- **FT-220/221/222/223**：OpenAI 429 / 5xx / 超时 / 空响应：锁定 SHA 没有对应单测；`src/bot.ts` 的 `createResponse` 用 `pRetry(…, {retries: openaiRetries})` 重试，失败后 `catch` 只告警并返回 `undefined`（静态阅读），但 `jest.config.json` 把 `p-retry` 替换成了 mock（`__mocks__/p-retry.js`），在单测里无法验证真实重试；本轮也无法对真实 OpenAI 做故障注入 → 记 N/A，列入报告“未覆盖风险”。
- **FT-224/225**：非法 JSON / Markdown 包裹 JSON：ai-reviewer 的审查输出不是 JSON 协议，而是“行号范围 + Markdown 评论”的文本格式（`src/review.ts` 里的 `JSON.parse` 只用来读取外部 lint 报告）→ 不适用，记 N/A。
- **FT-182**：搜索失败后安全降级：没有对应单测，也无法在真实环境阻断 web_search → 记 N/A。
- **FT-296/297**：OpenAI / GitHub API 并发限制：用 `p-limit` 实现（`src/review.ts`），`p-limit` 在 jest 中同样被 mock，且没有对应用例 → 记 N/A。

## 仍未判定

- FT-203 工具超时：同时依赖隔离环境（lint-on-isolated），保持 BLOCKED。
- FT-184~188、191~202：需要隔离环境，保持 BLOCKED。
