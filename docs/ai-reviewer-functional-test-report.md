# ai-reviewer develop 功能回归测试报告

> 模板：所有“待填写”由验收阶段根据真实证据填写。PASS/FAIL 汇总以 `docs/ai-reviewer-functional-test-progress.md` 的 FT 状态总表为准，本报告只引用，不重复维护。

## 测试版本

- 待测仓库：`CodesSentinels/ai-reviewer`（来源分支 `develop`）
- 锁定 SHA：`8c84f45fab547821ecefbf56aabbf215eb9d7dbf`
- SHA 获取时间：`2026-10-08T06:44:44Z`
- 测试仓库：`CodesSentinels/ai-reviewer-test`
- 测试分支：`test/ai-reviewer-develop-functional-20261008`
- 总回归 Issue：https://github.com/CodesSentinels/ai-reviewer-test/issues/299
- 测试 PR：待填写
- Workflow / Pipeline：待填写

## 环境

- 测试仓库技术栈（勘察结果）：Nuxt 3 + Vue 3 + Pinia，TypeScript；`eslint.config.js`（Flat Config，规则：no-unused-vars、no-console、eqeqeq、array-callback-return）；`biome.json`（范围仅 `utils/**`、`composables/**`）；`tsconfig.json` extends `./.nuxt/tsconfig.json`；`.codesentinel.yaml`（eslint/biome 开启，prettier 关闭）；无 prettier 配置；仓库内无 Jest/Vitest。
- 现有 workflow `.github/workflows/ai-reviewer.yml`：触发 pull_request（opened/synchronize/reopened）、pull_request_review_comment、issue_comment，以及 push（main、`test/dev*`）；通过 GitHub App token checkout ai-reviewer 并 `uses: ./.github/ai-reviewer-action`；secrets：APP_ID、APP_PRIVATE_KEY、OPENAI_API_KEY（另有 BOT_PAT，当前未启用）。
- bot 登录名：`codesentinel-review-bot[bot]`。
- 其他环境信息（Runner、账号角色、GitLab 环境、隔离环境）：待填写

## 基线与线上配置差异

- 测试基线采用安全加固配置：`enable_shell: false`、`enable_lint_tools: false`，ai-reviewer checkout 固定到锁定 SHA；另删除 `path_filters` 中的 `**/*.md`（md 不审查，避免测试文档占满 `max_files`）；
- 与线上/实际部署配置的差异：待填写（线上是否开启 shell、lint）；
- 依赖隔离环境的变体（shell-on-isolated / lint-on-isolated）：是否已运行、使用的环境、是否使用专用 key：待填写；
- 与 ai-reviewer 仓库较早测试计划（`docs/tasks/tester-1-core-review-testcases.md`、`tester-3-quality-control-testcases.md`，以 shell/lint 开启为前提）的差异：本轮以验收文档与生产 workflow 为准，沿用旧计划的用例已映射到隔离变体，不直接套用旧预期。

## 结果汇总

| 状态 | 数量 | 说明 |
|---|---|---|
| PASS | 待填写 | 引用进度文档 |
| FAIL | 待填写 | |
| BLOCKED | 待填写 | 单独计数，不算通过 |
| N/A | 待填写 | 需写明理由 |
| 其余（NOT_READY / READY / SUBMITTED / RUNNING / WAITING_FOR_FIX / RETEST） | 待填写 | |

## 缺陷

待填写（FT 编号 → 缺陷 Issue → 失败 SHA → 首次失败证据 → 当前状态）。

## 性能和成本

- 小 / 中 / 大 PR 执行时间（FT-290~292）：待填写
- light / heavy 模型调用数量（FT-293/294）：待填写
- 平台 API 调用情况（FT-295）：待填写

## Secret 检查

- 日志中无 OPENAI_API_KEY / GITHUB_TOKEN / GITLAB_PAT / Authorization header / 敏感 URL 参数（FT-231/232/233/250/251/252）：待填写
- 隔离环境未使用生产密钥：待填写

## 未覆盖风险

待填写（包括因缺少隔离环境、账号、GitLab 环境而 BLOCKED 的 FT，以及 N/A 的理由）。

## 发布建议

待填写
