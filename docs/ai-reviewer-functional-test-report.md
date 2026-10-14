# ai-reviewer develop 功能回归测试报告

> 本报告于 2026-10-10 根据真实证据填写。PASS/FAIL 汇总以 `docs/ai-reviewer-functional-test-progress.md` 的 FT 状态总表为准，本报告只引用，不重复维护。

## 测试版本

- 待测仓库：`CodesSentinels/ai-reviewer`（来源分支 `develop`）
- 锁定 SHA：`8c84f45fab547821ecefbf56aabbf215eb9d7dbf`
- SHA 获取时间：`2026-10-08T06:44:44Z`
- 测试仓库：`CodesSentinels/ai-reviewer-test`
- 测试分支：`test/ai-reviewer-develop-functional-20261008`
- 总回归 Issue：https://github.com/CodesSentinels/ai-reviewer-test/issues/299
- 测试 PR：[#300](https://github.com/CodesSentinels/ai-reviewer-test/pull/300)（主测试 PR，不合并）、[#304](https://github.com/CodesSentinels/ai-reviewer-test/pull/304)（命令/暂停/对话类卫星 PR，不合并）、[#310](https://github.com/CodesSentinels/ai-reviewer-test/pull/310)（配置变体 PR，不合并）；另有合入 main 的辅助 PR（锁定 SHA 的 workflow、FT-117 的临时改动 #312 与还原 #313）
- Workflow / Pipeline：`.github/workflows/ai-reviewer.yml`（GitHub Actions，checkout 固定到锁定 SHA）

## 环境

- 测试仓库技术栈（勘察结果）：Nuxt 3 + Vue 3 + Pinia，TypeScript；`eslint.config.js`（Flat Config，规则：no-unused-vars、no-console、eqeqeq、array-callback-return）；`biome.json`（范围仅 `utils/**`、`composables/**`）；`tsconfig.json` extends `./.nuxt/tsconfig.json`；`.codesentinel.yaml`（eslint/biome 开启，prettier 关闭）；无 prettier 配置；仓库内无 Jest/Vitest。
- 现有 workflow `.github/workflows/ai-reviewer.yml`：触发 pull_request（opened/synchronize/reopened）、pull_request_review_comment、issue_comment，以及 push（main、`test/dev*`）；通过 GitHub App token checkout ai-reviewer 并 `uses: ./.github/ai-reviewer-action`；secrets：APP_ID、APP_PRIVATE_KEY、OPENAI_API_KEY（另有 BOT_PAT，当前未启用）。
- bot 登录名：`codesentinel-review-bot[bot]`。
- 账号角色：PR 作者 linfei0211（仓库 ADMIN）及用于 fork 测试的账号 B；无 write / triage / read / 无权限账号；
- 范围：本报告只覆盖 GitHub。GitLab 相关用例（28 项）单独测试，不在本报告范围内，也不计入下面统计的分母；
- 隔离环境：已提供 ai-reviewer-test-iso（独立私有仓库，专用低额度 OpenAI key，只读 token）；shell 与 lint 阶段均已测。

## 基线与线上配置差异

- 测试基线采用安全加固配置：`enable_shell: false`、`enable_lint_tools: false`，ai-reviewer checkout 固定到锁定 SHA；另删除 `path_filters` 中的 `**/*.md`（md 不审查，避免测试文档占满 `max_files`）；
- 与线上/实际部署配置的差异：基线关闭了 shell 与 lint；若线上开启，则 FT-184~203 对线上配置的结论完全没有覆盖（见“未覆盖风险”）；
- 依赖隔离环境的变体（shell-on-isolated / lint-on-isolated）：shell-on-isolated 已在 ai-reviewer-test-iso 运行（专用 key）；lint-on-isolated 已在同一隔离仓库运行（PR #2，7 个阶段）；
- 与 ai-reviewer 仓库较早测试计划（`docs/tasks/tester-1-core-review-testcases.md`、`tester-3-quality-control-testcases.md`，以 shell/lint 开启为前提）的差异：本轮以验收文档与生产 workflow 为准，沿用旧计划的用例已映射到隔离变体，不直接套用旧预期。

## 验证范围说明（请先读）

- **完整功能回归（R1）运行的是旧构建**：dist 构建自 2026-09-07 的 `1a6f6606`（见 #319），它不包含后来合入的大型 PR 处理、严重级别标签解析、Analysis chain、审查质量提示词、GitLab 改动等。下面“结果汇总”里的大部分 PASS 取自 R1，对应的是这个旧构建。
- **发布候选版本 `24c87694`（develop，dist 与源码一致）上实际重新执行的是 R2~R4**：针对已修复缺陷的复测（FT-005/036/055/078/092/102/104/128/147/186/197/202）加基线冒烟，以及补测的 FT-182/220~223（单测）。其余 PASS 没有在该版本上重新执行。
- ai-reviewer 自带的 2837 条单元测试在该版本上全部通过，覆盖面广，但不能替代端到端回归。
- 因此：**可以说“发布候选版本经过针对性回归与抽样回归”，不能说“完整功能回归在该版本上全部通过”**。如需后一种结论，需要在 `24c87694` 上把主流程批次重新执行一遍（换 SHA 即可复用现有脚本）。

## R6 复测（#325 的修复）

- R6 SHA：`acc61bb5765e26285f27b5e45c68a08878dd7667`（ai-reviewer 分支 `fix/similar-comments-r5`，dist 对应源码 `a6028a02`，尚未合入 develop）。
- 重放 Phase 1~3 的新 PR [#327](https://github.com/CodesSentinels/ai-reviewer-test/pull/327)：many-issues.ts 的 30 个缺陷由 R5 的“10 条相同评论 + 20 处未发布”变成 3 条评论（eval、`==`、除零各一条），每条末尾列出其余 9 个位置；日志 `similar-merge: 39 findings → 12`，合并恰好减少 27 条且全部来自该文件，其他文件的评论没有被误合并。FT-093、FT-094 通过。
- 观察：Phase 1/2 的评论数比 R5 少（模型输出的运行间波动，日志里没有合并动作），所以依赖具体评论的用例仍以 R5 的证据为准。

## R5 补跑（发布候选版本 24c87694 上的完整回归，进行中）

- 批次 A（Phase 1~3 重放，PR #324，新分支 `test/r5-lane`）已完成：在 `24c87694` 上复核了 46 项，其中 44 项与 R1 结论一致；**FT-093、FT-094 失败**：同一文件里 10 处相同模式的缺陷各发一条完全相同的评论，占满评论额度，另 20 处缺陷未发布（R1 旧构建同一文件只产生 3 条合并评论）。缺陷 [#325](https://github.com/CodesSentinels/ai-reviewer-test/issues/325)。
- 这个失败**只有在发布候选版本上才出现**，正好说明在旧构建上取得的 PASS 不能直接代表新版本。
- 批次 B（命令与对话）、C（配置变体）、D（其余）尚未执行；未覆盖的项沿用 R1 结论，并在“验证范围说明”里注明。

## 结果汇总

| 状态    | 数量 | 说明                                                                                                                                                   |
| ------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| PASS    | 195  | 均有真实 run / 评论 / 日志或单测证据，见进度文档总表                                                                                                   |
| FAIL    | 0    | R1 的 11 项 FAIL 经 R2/R3/R4 复测通过；R5 发现的 FT-093/094（缺陷 #325）经修复后在 R6 复测通过，修复在分支 `fix/similar-comments-r5`，尚未合入 develop |
| BLOCKED | 0    | 无                                                                                                                                                     |
| N/A     | 2    | FT-296/297（并发限制：用户称已自行验证正常但没有留存证据；真实 run 日志只显示并发请求数未超过上限，不足以证明限制生效）                                |
| 其余    | 1    | SUBMITTED 1（FT-295，API 调用统计不完整）。FT-213 经用户确认判 PASS，FT-300 即本报告判 PASS                                                            |

统计口径：本报告只覆盖 GitHub。226 项中 GitLab 28 项不在本轮范围，本轮范围 198 项：PASS 195、FAIL 0、N/A 2、未完成 1（FT-295）。

## R2 复测（修复后的 SHA）

- R2 SHA：`c96cd53e0c1a23abf85ecb21c5a0e90a255333c5`（ai-reviewer 分支 `fix/regression-defects-r1`，dist 重新打包自源码提交 `1ca3e94`）。该分支未合入 develop。
- 复测范围：已修复的 7 个缺陷（#302、#307、#309、#315、#316、#317、#318）及对应 FT-078、102、104、147、186、197、202，**全部通过**；基线冒烟（自动审查增量起点、lint/shell 默认关闭、新增 `warn_files`）正常。
- 未复测（未修复）：#301、#303、#305、#308、#311；以及 #319（dist 落后，需要发布流程修复）。
- 教训：R1 的端到端 run 实际运行的是 2026-09-07 的旧 dist（见 #319），R2 才是第一次用“包含修复的 dist”测试。

## R3 复测（第二批修复）

- R3 SHA：`b73adc3e2630bf70241298e515b59bfc5d727917`（dist 对应源码 `66468ab2c85bd28d457b57c3d63b4cdd729b3dc9`），仍在修复分支 `fix/regression-defects-r1`，未合入 develop。
- 复测范围与结果：FT-005（缺 key 时 job 红色失败）、FT-128（12 条连发后第 11、12 条被限流并提示）、FT-092（截断后补发且不重复已发）、FT-055（同一问题不重复）、FT-036（仅格式化判 APPROVED）——**全部通过**。
- 需要说明：FT-055/092 的真实 run 中生效的是位置层去重，新增的内容层去重（同一问题换行范围）由单测证明；FT-036 是提示词优化，模型行为可能波动，本次为单次通过。
- 至此 R1 的 11 项 FAIL 全部复测通过。

## R4 抽样回归（合入 develop 后）

- R4 SHA：`24c87694013c9e5655a920404e582123cbde09fd`（develop 最新，PR #167 合入后重新打包 dist；`dist/SOURCE_SHA` = `9f20f5b1`，已核对与源码一致）。这是第一个“修复已合入 develop 且 dist 完整”的版本。
- 抽样范围与结果：FT-005、036、055、078、102、104、128、186、197、202 均再次通过；FT-092 截断与去重生效，但补发不完整（见下）；FT-147 用户确认不测，沿用 R2 结论。
- 内容层去重在真实 run 中生效 9 次；上游新增的“与 patch 不重叠的评论丢弃”未触发，无副作用。
- 观察项 [#323](https://github.com/CodesSentinels/ai-reviewer-test/issues/323)：被 `max_review_comments` 截断的 finding 没有持久化，full review 补发依赖模型重新生成，只补发了 2 条被截断 finding 中的 1 条。FT-092 仍判 PASS（R3 完整补发 3 条），但补发不保证完整。
- 流程问题 #319 重演：合入后 develop 的 dist 再次落后一个提交（上游 `b3cf8e2`），靠手工重新打包补上。

## 缺陷

失败 SHA 均为 `8c84f45f`，状态均为 WAITING_FOR_FIX，修复后以新 SHA 开新轮次复测（失败证据保留）。

| 严重度（测试方判断） | FT     | 缺陷                                                                  | 现象                                                                                                                                                                    |
| -------------------- | ------ | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 高                   | FT-078 | [#302](https://github.com/CodesSentinels/ai-reviewer-test/issues/302) | 一次 push 改动 62 个文件时增量审查只处理 compare 列表前 30 个，其余文件被静默漏审（compare API 另有 300 文件上限）                                                      |
| 中（已更正）         | FT-092 | [#305](https://github.com/CodesSentinels/ai-reviewer-test/issues/305) | 更正：SQL 注入与明文令牌其实已被合并进同一条评论发布（并非丢弃）；真正的问题是已发布的 loadAll 换了行范围后被重复发布，与 #303 同类                                     |
| 中                   | FT-055 | [#303](https://github.com/CodesSentinels/ai-reviewer-test/issues/303) | 去重只认完全相同的行范围，同一问题换范围后重复发布                                                                                                                      |
| 中                   | FT-005 | [#311](https://github.com/CodesSentinels/ai-reviewer-test/issues/311) | OPENAI_API_KEY 为空时 run 仍 success，只有一条 warning，无明确失败                                                                                                      |
| 中                   | FT-104 | [#309](https://github.com/CodesSentinels/ai-reviewer-test/issues/309) | HEAD 已审查过时 `review` 退回到从 base 全量重审                                                                                                                         |
| 中                   | FT-036 | [#301](https://github.com/CodesSentinels/ai-reviewer-test/issues/301) | 仅格式化改动被判 NEEDS_REVIEW 并给出🔴严重评论（预期忽略轻微样式）                                                                                                      |
| 中                   | FT-147 | [#315](https://github.com/CodesSentinels/ai-reviewer-test/issues/315) | triage 角色被识别为 read（读取了 GitHub 旧字段 `permission`，triage 被折叠成 read），triage 用户无法执行 `configuration`；拒绝文案也固定写“需要 write”                  |
| 中                   | FT-186 | [#316](https://github.com/CodesSentinels/ai-reviewer-test/issues/316) | shell 命令输出无任何脱敏，仅删除 4 个环境变量键；token 形态字符串原样回传模型                                                                                           |
| 中                   | FT-197 | [#317](https://github.com/CodesSentinels/ai-reviewer-test/issues/317) | CI 下 Prettier 输出带 ANSI 颜色码，适配器正则不匹配，显式开启 Prettier 后永远 0 发现且无告警                                                                            |
| 低（观察项）         | FT-202 | [#318](https://github.com/CodesSentinels/ai-reviewer-test/issues/318) | npm 工具安装失败（如版本号写错）后，同一目录里 Prettier 的可执行文件消失，Prettier 静默 0 发现；FT-202 本身判 PASS                                                      |
| 高（流程）           | 无     | [#319](https://github.com/CodesSentinels/ai-reviewer-test/issues/319) | develop 与 main 的 `dist/` 构建自 2026-09-07 的 `1a6f6606`，落后源码 45 个提交；GitHub Action 实际运行 dist，所以 R1 的端到端 run 代表的是该旧构建，而非锁定 SHA 的源码 |
| 低                   | FT-102 | [#307](https://github.com/CodesSentinels/ai-reviewer-test/issues/307) | `@codesentinel-review-bot help` 无回复无 reaction，日志 ignored（no bot mention）                                                                                       |
| 低（已知限制）       | FT-128 | [#308](https://github.com/CodesSentinels/ai-reviewer-test/issues/308) | 命令限流为进程内内存，Actions 每次一个进程，12 条连发全部执行                                                                                                           |

## 性能和成本

- 执行时间（FT-290~292）：1 文件 52 秒；3 文件 50 秒；Phase 2 增量 8 文件 80 秒；PR #300 首次审查按 max_files=150 处理 150 个文件，375 秒（约 6 分 15 秒）。
- 模型调用（FT-293/294）：light（gpt-5.4-nano）每文件 1 次（1/3/8/150 次）；heavy（gpt-5.4-mini）文件审查 1/3/8/150 次，含 web_search 与 analysis chain 后 sendMessage 总数 5/7/12/168。
- 平台 API 调用（FT-295，未判 PASS）：只能从日志取得依赖分析阶段的 GitHub API 调用数（1 文件 46、3 文件 40 …），其余阶段无统计，状态保持 SUBMITTED。

## Secret 检查

- 日志中无 Authorization header、token/API key 形态字符串、敏感 URL 参数（FT-231/232/233 PASS）；OPENAI_API_KEY、GITHUB_TOKEN 仅以变量名出现，值为 `***`（FT-250/251 PASS）。
- 隔离环境：已提供（ai-reviewer-test-iso，仅含专用低额度 OpenAI key 与只读 token，无 App 私钥/BOT_PAT）；shell 变体在该仓库运行，未使用生产密钥。

## 未覆盖风险

0. **测试有效性说明（#319）**：锁定 SHA `8c84f45f` 的 `dist/` 构建自 `1a6f6606`（2026-09-07），因此 R1 所有端到端 run 运行的是该 dist；基于“源码 + 单测”得出的结论代表锁定 SHA 的源码，两者可能不一致。R2 必须选择 dist 已重新打包的提交。
1. **shell 与 lint 已在隔离环境测过**（隔离仓库 ai-reviewer-test-iso，专用低额度 OpenAI key 与只读 token）：shell FT-184/185/187/188 PASS、FT-186 FAIL；lint FT-191~196/198~203 PASS、FT-197 FAIL。仅覆盖锁定 SHA 与上述配置，未覆盖更多项目类型（如 Vue、monorepo）。
2. **权限矩阵已测，但 none 用户只有单测证据**：read（含 PR 作者豁免与 pause/resume/resolve 被拒）、write 已在真实 PR 验证；triage 正向用例失败（FT-147，缺陷 #315）；none 用户无法在 GitHub 上构造（私有仓库无权限者无法评论，公开仓库 API 对所有人返回 read），FT-149/151 以单测与 read 角色的真实拒绝回复判 PASS。另观察到 configuration 被拒时的文案写“需要 write”，与 help 表（triage）不一致。
3. **fork PR 已测（FT-240~242 PASS），但仅限同一组织内的 fork**：fork 账号 B 为组织成员，且测试时临时开启“运行 fork PR workflow”（不发送 Secret）；外部陌生贡献者、需要审批的场景未单独验证。
4. **容错路径已用单测补证**（FT-182、220~223，ai-reviewer develop 24c87694，真实 p-retry，15/15 通过）：429/5xx/超时重试后恢复，持续失败时返回空文本且不抛异常，空响应被记入“审查不完整”提示。并发限制（FT-296/297）没有留存证据（用户称已自行验证正常）。记录行为：401/400 等不可重试的客户端错误也被重试（默认约 31 秒），web_search 被拒时没有“去掉搜索再试”的回退。
5. **FT-213 已判 PASS（用户确认），但仅限基线**：基线下持密钥 job 在 pull_request 事件检出 PR 的 merge commit（`actions/checkout` 默认行为）；action 代码来自单独固定 SHA 的 checkout，shell/lint 关闭时 PR 代码不会被执行。若线上开启 shell/lint，该结论不成立。
6. **FT-295** API 调用统计不完整。
7. 其他注意：`debug_resolve_inject_failures` 在该 SHA 不生效，FT-061 以单测证据替代；限流缺陷 #308 为架构限制。

## 发布建议

**GitHub 范围内可以发布。发布候选版本是 develop 最新 `4684cad355cb86dc049b6ded0221de68d7d92025`（PR #174 合入后）。**

- 该提交的 `dist/SOURCE_SHA` 是 `a6028a02`，自该提交以来 `src/` 没有差异；git 树与 R6 测过的 `acc61bb5` 完全一致，所以 R6 的结论直接适用。
- 所有缺陷（R1 的 11 个、R5 发现的 #325）都已修复、复测并关闭；保持打开的只有 #319（dist 落后源码，上游 `ai-reviewer#168`）和 #323（观察项，上游 `ai-reviewer#169`）。

发布前请确认：

1. **dist 与发布提交一致**：当前满足；上游还没有加 CI 检查，下次合入可能再落后。
2. **行为变化已写入发布说明**：见 `docs/ai-reviewer-release-notes-draft.md`（缺 `OPENAI_API_KEY` 时 job 失败、命令限流、`triage` 权限、shell 输出脱敏、提示词调整、同一问题去重、同类评论合并只锚定第一个位置）。
3. **验证范围**：完整功能回归主要取自旧构建（见“验证范围说明”）；发布候选版本上做了针对性回归、抽样回归和 R5/R6 的 Phase 1~3 重放（46 项复核）。批次 B（命令与对话）、C（配置变体）、D 经发布负责人决定**不补跑**，这部分沿用 R1 的结论。
4. **已知限制**：被 `max_review_comments` 截断的问题补发不保证完整（#323）；401/400 等不可重试错误也被重试；web search 被拒时没有回退。

GitLab 另行验证，不在本报告范围内。核心路径（PR 触发审查、增量审查、去重幂等、暂停/恢复、对话追问、权限、限流、Secret 不泄露、shell 与 lint 工具链）在隔离环境与基线下通过，GitHub 范围 198 项中 195 项 PASS、0 项 FAIL。
