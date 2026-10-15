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

## 补充（2026-10-09 第二批）：陈旧 HEAD、长评论链、仓库树缓存隔离

同样在锁定 SHA `8c84f45fab547821ecefbf56aabbf215eb9d7dbf` 的临时克隆上运行：`__tests__/review-head-freshness.test.ts`（26 个用例）、`repo-tree-cache-isolation.test.ts`、`conversation.test.ts`、`comment-chain-status.test.ts`、`conversation-dual-platform.test.ts`（合计 79 个用例，全部通过）。

### FT-056 旧 HEAD 不覆盖新结果 / FT-057 陈旧事件安全跳过

- `review-head-freshness.test.ts` — 分析后 HEAD 变化 → 不写 release notes / 摘要 / 行级评论 — **passed**
- `review-head-freshness.test.ts` — 最危险的一条：不写 reviewed SHA marker（否则新 HEAD 会被当成已审过） — **passed**
- `review-head-freshness.test.ts` — 逐文件审查（阶段四）执行期间推了新 commit → 行级评论与摘要都不写 — **passed**
- `review-head-freshness.test.ts` — 作废提示不去读改写摘要评论（旧任务不得覆盖新任务结果） — **passed**
- 真实环境补充：卫星 PR #304 上重跑旧 run（37891781681 的 attempt 2、3，对应旧 HEAD 88b8c0a6，当前 HEAD 为 6502eb86）日志为 `Skipped: headSha 88b8c0a6… already reviewed (idempotency key …)`，OpenAI 请求数 0，未产生任何评论。

### FT-165 长评论链安全截断

- `conversation.test.ts` — truncateConversationChain — 截断与压缩 超长对话保留最近内容并标注省略 — **passed**
- `conversation.test.ts` — truncateConversationChain — 截断与压缩 预算极小也至少保留最新一轮 — **passed**
- `conversation.test.ts` — truncateConversationChain — 截断与压缩 短对话原样返回 — **passed**

### FT-178 仓库树缓存不跨 PR 污染

- `repo-tree-cache-isolation.test.ts` — TEST-039：key 的每个维度都必须参与隔离 只改 ref → 不命中缓存，重新拉取 — **passed**
- `repo-tree-cache-isolation.test.ts` — TEST-039：key 的每个维度都必须参与隔离 两个项目交替访问，各自拿到自己的文件列表 — **passed**
- `repo-tree-cache-isolation.test.ts` — TEST-039：key 的每个维度都必须参与隔离 对照组：四维全同确实命中（证明上面不是「永远不命中」） — **passed**
- `repo-tree-cache-isolation.test.ts` — API 失败 后续请求失败不破坏已有缓存，也不返回别人的数据 — **passed**
- 说明：缓存 key 由 platform + owner + repo + ref 组成，ref 为各 PR 的 head，所以不同 PR 互不共用。

### FT-185 / FT-186 shell 超时、输出限制与脱敏（锁定 SHA clone 中运行，`bot.runLocalShellCall`）

- 测试文件：`functional-tests/ai-reviewer-fixtures/unit-evidence/shell-safety.test.ts`（复制到 ai-reviewer 的 `__tests__/` 下执行 `npx jest __tests__/zz-shell-evidence.test.ts`）
- 超时：`timeout_ms=500` 的 `sleep 10` 在约 0.5s 内被终止，outcome 为 `{type: 'timeout'}` — **passed**
- 输出上限：默认 4096 字符，超出部分截断并带 `(truncated)` 标记 — **passed**；`max_output_length=100` 被遵守 — **passed**
- 环境变量：`OPENAI_API_KEY`、`GITHUB_TOKEN` 不进入子进程；其他变量（如 `FAKE_OTHER_SECRET`）仍可见 — **passed**
- 输出脱敏：`sk-proj-…`、`ghp_…` 形态字符串原样返回，**没有脱敏**（FT-186 判 FAIL，缺陷 [#316](https://github.com/CodesSentinels/ai-reviewer-test/issues/316)）
- 说明：全量 jest 中另有 3 个与 GitLab CI / bundle 产物相关的套件失败（`gitlab-ci-security-scenarios`、`gitlab-ci-config`、`ci-trigger-bundle-provenance`），属于本地环境缺少构建产物，与本 FT 无关。

### FT-203 lint 工具超时安全处理（锁定 SHA clone 中运行）

- 测试文件：`functional-tests/ai-reviewer-fixtures/unit-evidence/lint-timeout-real.test.ts`、`lint-timeout-adapter.test.ts`（复制到 ai-reviewer 的 `__tests__/` 下运行）
- `DEFAULT_TOOL_TIMEOUT_MS` 为 60 秒 — **passed**
- `runCommand({command:'sleep', args:['10'], timeoutMs:300})` 约 0.3 秒被终止，返回 `timedOut=true`，不抛异常 — **passed**
- 命令不存在时返回 `spawnError=true`，不抛异常 — **passed**
- Biome 扫描超时（mock `runCommand` 返回 timedOut）→ findings 为空，不抛异常 — **passed**

### FT-149 / FT-151 权限 none 与 GitHub 权限术语（锁定 SHA clone 中运行）

- 无法在真实 GitHub 上构造 `none` 用户：私有仓库中无权限者看不到仓库也不能评论；公开仓库的 `collaborators/{user}/permission` 对任何人都返回 `read`（用账号 B 在临时公开的隔离仓库核对，随后改回私有）。
- `command-permission-matrix.test.ts` + `command-permission.test.ts`（共 55 条通过）：
  - 各命令低于最低权限（help=read、configuration=triage、其余=write）一律拒绝 — **passed**
  - 外部贡献者（权限 none）在自己 PR 上只能触发豁免集内命令（help/review/full review/summary） — **passed**
  - API 抛错 / 用户不存在 → 权限为 none，查询失败时所有命令都被拒绝（fail closed） — **passed**
  - none 在 help 要求 read 时不能执行 help — **passed**
- `platform-terms.test.ts`（11 条通过）：GitHub 保持 `write`/`read` 等内部权限名，GitLab 换成项目角色名 — **passed**
- 真实回复（PR #314，B=read 执行 pause）：“需要仓库 `write` 及以上权限……当前权限: `read`”。

### FT-220 / 221 / 222 / 223 / 182 OpenAI 调用容错与 web_search 失败降级（ai-reviewer develop 24c87694）

- 脚本：`functional-tests/ai-reviewer-fixtures/unit-evidence/openai-resilience.cjs`，15/15 通过。用 Node 直接加载 ai-reviewer 的 CommonJS 编译副本，使用**真实 p-retry**（jest 配置把 p-retry 映射成“只调用一次”的 mock，所以 jest 里测不到重试），假的 OpenAI 客户端按脚本返回错误或响应。
- FT-220：连续 2 次 429 后成功（调用 3 次）— **passed**；持续 429 重试耗尽后返回空文本、不抛异常 — **passed**。
- FT-221：500、503 后成功 — **passed**；持续 502 返回空文本 — **passed**；记录行为：401 也被重试 — **passed（记录）**。
- FT-222：超时 1 次后成功（调用 2 次）— **passed**；持续超时返回空文本 — **passed**；客户端 timeout 取自配置、SDK 自带重试关闭 — **passed**。
- FT-223：output 空数组 / null / 无 output_text / 空消息 — **passed**（空文本、不抛异常、空消息不调 API）。
- FT-182：web_search 失败但有正文 → 返回正文并记录失败步骤 — **passed**；开关关闭时不记录 web_search_call — **passed**；带 web_search 的请求被 400 拒绝 → 空文本不抛异常 — **passed**。
- 失败的呈现：模型无响应时 `bot.chat` 返回空文本，`review.ts` 把空响应记入 `summariesFailed` / `reviewsFailed`，据此生成“审查不完整”提示（REVIEW-006），不会静默当成无问题。

### FT-224 / FT-225 模型生成 JSON 的安全处理（ai-reviewer develop，工具调用参数）

- 脚本：`functional-tests/ai-reviewer-fixtures/unit-evidence/review-tools-json-args.cjs`，8/8 通过。产品的审查输出不是 JSON，但模型发起只读代码探查工具调用时，`arguments` 是模型生成的 JSON 字符串（`src/review-tools.ts` 的 `executeReviewTool` 用 `JSON.parse` 解析）。
- FT-224：截断 JSON、纯文本、空字符串、合法但非对象（数组 / null / 数字）、类型错误、路径穿越 — 全部以 error 文本返回，**passed**，不抛异常。
- FT-225：被 Markdown 围栏包住的 JSON 不解包，按“arguments are not valid JSON”安全拒绝 — **passed**；未知工具名返回 unknown tool — **passed**。

## 并发限制（FT-296/297，后补）

- 脚本：`functional-tests/ai-reviewer-fixtures/unit-evidence/review-concurrency-limits.test.ts`（放入 ai-reviewer 的 `__tests__/` 运行，develop 4684cad3，6/6 通过）。
- 做法：jest 把 `p-limit`（仅 ESM）映射成透传 shim，所以此前测不到。这里用一个真正排队的限流器替换它，驱动完整的 `codeReview`（8 个文件），量同时在飞数的峰值：模型调用（light + heavy 共用 `openaiConcurrencyLimit`）和 `getFileContent`（`githubConcurrencyLimit`）。
- 结果：openai=1 → 峰值 1，openai=3 → 峰值 3（FT-296）；github=1 → 峰值 1，github=2 → 峰值 2（FT-297）；openai=2、github=3 两个上限互相独立；对照组上限放宽到 8，峰值升高（文件读取 8），证明量法有分辨力。
- 变异验证：把 `pLimit(options.openaiConcurrencyLimit)` 临时改成 `pLimit(99)`，3 条 FT-296 相关用例失败；对 github 同样改动，3 条 FT-297 相关用例失败；已还原。
- 另用 Node 24 直接加载真实 `p-limit` 4.0.0，8 个任务在 n=1/2/3 下峰值分别为 1/2/3，与测试里的限流器语义一致。
- 边界：FT-297 覆盖的是审查流程里读取文件内容这一处 GitHub 调用（`review.ts` 中走 `githubConcurrencyLimit` 的位置）；依赖分析中另一处使用同一限制器的调用未单独量。

## 仍未判定

- FT-191~202：隔离环境的 lint 阶段（FT-184~188 已在隔离仓库完成）。
