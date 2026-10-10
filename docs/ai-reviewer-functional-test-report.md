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
- 账号角色：仅有 PR 作者 linfei0211（仓库 ADMIN）一个账号，无 write / triage / read / 无权限 / fork 账号；
- GitLab：本轮不测（用户确认后续单独测试）；
- 隔离环境：未提供（无无密钥的隔离仓库/Environment，也无专用 key）。

## 基线与线上配置差异

- 测试基线采用安全加固配置：`enable_shell: false`、`enable_lint_tools: false`，ai-reviewer checkout 固定到锁定 SHA；另删除 `path_filters` 中的 `**/*.md`（md 不审查，避免测试文档占满 `max_files`）；
- 与线上/实际部署配置的差异：基线关闭了 shell 与 lint；若线上开启，则 FT-184~203 对线上配置的结论完全没有覆盖（见“未覆盖风险”）；
- 依赖隔离环境的变体（shell-on-isolated / lint-on-isolated）：未运行（无隔离环境、无专用 key），相关 FT 全部 BLOCKED；
- 与 ai-reviewer 仓库较早测试计划（`docs/tasks/tester-1-core-review-testcases.md`、`tester-3-quality-control-testcases.md`，以 shell/lint 开启为前提）的差异：本轮以验收文档与生产 workflow 为准，沿用旧计划的用例已映射到隔离变体，不直接套用旧预期。

## 结果汇总

| 状态    | 数量 | 说明                                                                                                                                                                                  |
| ------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| PASS    | 148  | 均有真实 run / 评论 / 日志或单测证据，见进度文档总表                                                                                                                                  |
| FAIL    | 8    | FT-005/036/055/078/092/102/104/128，对应 8 个缺陷 Issue                                                                                                                               |
| BLOCKED | 32   | 无额外账号 14 项（FT-140~149、151、240~242）+ 无隔离环境 18 项（FT-184~188、191~203）；不算通过                                                                                       |
| N/A     | 37   | GitLab 28 项（后续单独测试）；OpenAI 重试/超时/空响应 FT-220~223、非 JSON 协议 FT-224/225、web_search 失败降级 FT-182、并发限制 FT-296/297（锁定 SHA 无对应单测且无法在真实环境注入） |
| 其余    | 1    | SUBMITTED 1（FT-295，API 调用统计不完整）。FT-213 经用户确认判 PASS，FT-300 即本报告判 PASS                                                                                           |

## 缺陷

失败 SHA 均为 `8c84f45f`，状态均为 WAITING_FOR_FIX，修复后以新 SHA 开新轮次复测（失败证据保留）。

| 严重度（测试方判断） | FT     | 缺陷                                                                  | 现象                                                                                                               |
| -------------------- | ------ | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| 高                   | FT-078 | [#302](https://github.com/CodesSentinels/ai-reviewer-test/issues/302) | 一次 push 改动 62 个文件时增量审查只处理 compare 列表前 30 个，其余文件被静默漏审（compare API 另有 300 文件上限） |
| 高                   | FT-092 | [#305](https://github.com/CodesSentinels/ai-reviewer-test/issues/305) | 同行范围的不同问题被合并，SQL 注入、明文令牌评论被静默丢弃；已发布问题却重复发布                                   |
| 中                   | FT-055 | [#303](https://github.com/CodesSentinels/ai-reviewer-test/issues/303) | 去重只认完全相同的行范围，同一问题换范围后重复发布                                                                 |
| 中                   | FT-005 | [#311](https://github.com/CodesSentinels/ai-reviewer-test/issues/311) | OPENAI_API_KEY 为空时 run 仍 success，只有一条 warning，无明确失败                                                 |
| 中                   | FT-104 | [#309](https://github.com/CodesSentinels/ai-reviewer-test/issues/309) | HEAD 已审查过时 `review` 退回到从 base 全量重审                                                                    |
| 中                   | FT-036 | [#301](https://github.com/CodesSentinels/ai-reviewer-test/issues/301) | 仅格式化改动被判 NEEDS_REVIEW 并给出🔴严重评论（预期忽略轻微样式）                                                 |
| 低                   | FT-102 | [#307](https://github.com/CodesSentinels/ai-reviewer-test/issues/307) | `@codesentinel-review-bot help` 无回复无 reaction，日志 ignored（no bot mention）                                  |
| 低（已知限制）       | FT-128 | [#308](https://github.com/CodesSentinels/ai-reviewer-test/issues/308) | 命令限流为进程内内存，Actions 每次一个进程，12 条连发全部执行                                                      |

## 性能和成本

- 执行时间（FT-290~292）：1 文件 52 秒；3 文件 50 秒；Phase 2 增量 8 文件 80 秒；PR #300 首次审查按 max_files=150 处理 150 个文件，375 秒（约 6 分 15 秒）。
- 模型调用（FT-293/294）：light（gpt-5.4-nano）每文件 1 次（1/3/8/150 次）；heavy（gpt-5.4-mini）文件审查 1/3/8/150 次，含 web_search 与 analysis chain 后 sendMessage 总数 5/7/12/168。
- 平台 API 调用（FT-295，未判 PASS）：只能从日志取得依赖分析阶段的 GitHub API 调用数（1 文件 46、3 文件 40 …），其余阶段无统计，状态保持 SUBMITTED。

## Secret 检查

- 日志中无 Authorization header、token/API key 形态字符串、敏感 URL 参数（FT-231/232/233 PASS）；OPENAI_API_KEY、GITHUB_TOKEN 仅以变量名出现，值为 `***`（FT-250/251 PASS）；GITLAB_PAT 因不测 GitLab 为 N/A（FT-252）。
- 隔离环境：未提供，未运行任何开启 shell/lint 的变体，因此不存在隔离环境使用生产密钥的情况。

## 未覆盖风险

1. **shell / lint 工具链完全未测**（FT-184~203，18 项 BLOCKED）：若线上开启 `enable_shell` 或 `enable_lint_tools`，沙箱、超时、脱敏、诱导读取环境变量/凭据目录等风险没有证据。
2. **权限矩阵未测**（FT-140~149、151，共 11 项）：只验证了 ADMIN 作者；write/triage/read/无权限用户的授权边界、作者豁免范围没有证据。
3. **fork PR 未测**（FT-240~242）：fork 下 Secret 不暴露、artifact 不可信等没有证据。
4. **GitLab 全部未测**（28 项 N/A）：后续单独一轮。
5. **容错路径无证据**（FT-182、220~225、296、297）：OpenAI 429/5xx/超时/空响应、web_search 失败降级、并发限制，锁定 SHA 无对应单测且无法在真实环境注入。
6. **FT-213 已判 PASS（用户确认），但仅限基线**：基线下持密钥 job 在 pull_request 事件检出 PR 的 merge commit（`actions/checkout` 默认行为）；action 代码来自单独固定 SHA 的 checkout，shell/lint 关闭时 PR 代码不会被执行。若线上开启 shell/lint，该结论不成立。
7. **FT-295** API 调用统计不完整。
8. 其他注意：`debug_resolve_inject_failures` 在该 SHA 不生效，FT-061 以单测证据替代；限流缺陷 #308 为架构限制。

## 发布建议

**不建议无条件发布该 SHA；建议“修复高/中缺陷后复测，再发布”。**

- 发布前必须修复并复测：#302（漏审文件）、#305（严重问题静默丢弃与重复发布）、#303（重复评论）。这三项会让用户拿到不完整或带重复的审查结果，且无任何提示。
- 建议同批修复：#311（缺少 key 仍报成功会掩盖配置错误）、#309、#301。
- 可后续迭代：#307、#308（影响面小，#308 为已知架构限制，可在文档中说明）。
- 若发布方接受风险，可以带条件发布：线上保持 `enable_shell:false`、`enable_lint_tools:false`，并仅用于可信的同仓库 PR，不依赖 `max_review_comments` 截断与超过 300 文件的大 PR；shell/lint、权限矩阵、fork、GitLab 需在补齐环境后另行回归。
- 核心路径（PR 触发审查、增量审查、去重幂等、暂停/恢复、对话追问、Secret 不泄露）在基线下通过，148/226 项 PASS。
