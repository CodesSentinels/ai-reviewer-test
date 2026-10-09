# ai-reviewer develop 功能回归：进度文档（跨会话续作入口）

> 新会话先读本文件，按“下一步”继续；不要重做已完成的步骤。FT 定义以 `functional-tests/ai-reviewer-fixtures/case-map.tsv` 为准，对外验收视图是总回归 Issue。只记录 URL、SHA、状态与命令摘要，不记录任何 Secret。

## Meta

- round: R1
- ai_reviewer_sha: 8c84f45fab547821ecefbf56aabbf215eb9d7dbf
- sha_fetched_at: 2026-10-08T06:44:44Z
- test_branch: test/ai-reviewer-develop-functional-20261008
- base_branch: main
- issue_url: https://github.com/CodesSentinels/ai-reviewer-test/issues/299
- issue_number: 299
- pr_url: https://github.com/CodesSentinels/ai-reviewer-test/pull/300
- pr_number: 300
- default_workflow: .github/workflows/ai-reviewer.yml
- workflow_active_variant: baseline
- baseline_profile: secure(shell=false, lint=false)
- isolated_env: pending
- current_stage: PHASE3_SUBMITTED
- last_updated: 2026-10-09T03:40:00Z
- last_updated_by_step: 读取 Phase 3 增量审查（run 37875759051）：发现只处理 30/62 个文件（缺陷 #302），5 项 PASS、FT-078 FAIL；等待用户提交文档并发 full review

## 下一步（Next Actions）

1. 用户：提交并推送本次更新的进度文档（只有 md，会被路径过滤排除；pull_request run 会因没有可审查文件而跳过，且不会把 HEAD 记为已审查）。
   - 提交前：`npx prettier --check docs/ai-reviewer-functional-test-progress.md`
   - `git add docs/ai-reviewer-functional-test-progress.md`
   - commit 消息：`docs: 记录 Phase 3 验收结果，增量审查只处理前 30 个文件（缺陷 #302）`
   - `git commit -m "docs: 记录 Phase 3 验收结果，增量审查只处理前 30 个文件（缺陷 #302）" && git push`
2. 用户：推送后在 PR #300 顶层评论发布 `@ai-reviewer full review`。目的：full review 走的是分页的文件列表（此前 270 / 18 个文件都处理正常），应当把被 #302 丢弃的 noise/、revert/rules.ts、unresolved/、many/013~040 等文件补审，取证 FT-058、FT-090~094、FT-177、FT-077（默认值下）。把 run 链接发给 Claude。无需单独提交。
3. Claude：读取 full review，判定上述 FT；并检查 full review 是否也有文件数截断。
4. 用户：之后做配置变体轮次（`simple-changes` 复测 FT-037、`no-path-filters` 验证 FT-074~076、`max-files`、`max-comments` 等）、命令类用例（G/H 分区）、隔离环境相关用例；每个变体的 commit 消息我会在对应步骤给出。
5. 用户（可并行）：确认基线偏差表，回答是否提供隔离环境；决定缺陷 #301、#302 是否通知 ai-reviewer 团队。

## 阶段与运行记录

| 阶段/变体 | 分支 | Commit SHA | PR | Workflow | 时间 | 状态 |
|---|---|---|---|---|---|---|
| Phase 1 | `test/ai-reviewer-develop-functional-20261008` | `4c47d40a` | [#300](https://github.com/CodesSentinels/ai-reviewer-test/pull/300) | [run 37742626690](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | 2026-10-08T07:18Z（耗时约 6m14s） | SUBMITTED |
| Phase 2 | `test/ai-reviewer-develop-functional-20261008` | `83140bc0` | 同一 PR | [run 37874287998](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) | 2026-10-09T02:22Z（约 1m20s） | SUBMITTED |
| Phase 3 | `test/ai-reviewer-develop-functional-20261008` | `88bf7db4` | 同一 PR | [run 37875759051](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | 2026-10-09T02:41Z（约 1m45s，仅处理 30/62） | SUBMITTED |

## 准备步骤清单

- [x] 解析 ai-reviewer develop 完整 SHA —— `8c84f45fab547821ecefbf56aabbf215eb9d7dbf`（2026-10-08T06:44:44Z）
- [x] 确认当前仓库为 `CodesSentinels/ai-reviewer-test`、工作区干净、gh 已登录（账号 linfei0211，权限 ADMIN） —— 起始于 main，工作区干净
- [x] 勘察测试仓库技术栈与现有 workflow（已写入报告“环境”） —— Nuxt 3 + Vue 3 + Pinia；ESLint flat config；Biome 仅 utils/composables
- [x] 创建测试分支 `test/ai-reviewer-develop-functional-20261008` —— 从 main 创建
- [x] 创建总回归 Issue —— https://github.com/CodesSentinels/ai-reviewer-test/issues/299
- [x] 创建 case-map.tsv、ft-ids.txt 与 cases/FT-XXX.md（全部 FT） —— 226 个用例
- [x] 创建 Bash 脚本与 check-case-map.sh（bash 3.2 兼容）
- [x] 创建 config-variants/（22 个变体说明）
- [x] 按基线修改 `.github/workflows/ai-reviewer.yml`（固定 SHA、shell=false、lint=false，未提交）
- [x] 创建 README 与报告模板
- [x] 创建进度文档与项目 CLAUDE.md 续作指引
- [x] 第二十一节验证全部通过

## FT 状态总表

汇总：共 226 项；PASS 55 / FAIL 2 / BLOCKED 0 / N/A 0 / 其余 169（NOT_READY 155、SUBMITTED 14）。

### A. 环境与启动

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-001 | 确认测试仓库正确 | local-validation | e2e | yes | no | PASS | [PR](https://github.com/CodesSentinels/ai-reviewer-test/pull/300) | - | 2026-10-08 | PR #300 位于 ai-reviewer-test；本地 --case FT-001 为 LOCAL_CHECK_PASS |
| FT-002 | 成功解析 develop 完整 SHA | local-validation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | ls-remote 与 run 日志 fetch 的 SHA 均为 8c84f45f… |
| FT-003 | Action 固定引用完整 SHA | local-validation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | checkout ref 与 FETCH_HEAD 均为完整锁定 SHA |
| FT-004 | Node 24 下成功加载 | external-observation | unit-evidence | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | SHA 处 action.yml 为 runs.using: node24，action 步骤成功 |
| FT-005 | 缺少必要配置时明确失败 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-006 | 未知或无关事件安全跳过 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-007 | debug=false 不输出敏感内容 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-008 | debug=true 仍不泄漏 Token | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | debug=true；日志无 token 形态字符串，Secret 均为 *** |
| FT-009 | workflow 使用最小权限 | local-validation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 日志 GITHUB_TOKEN 权限：contents read / issues write / pull-requests write |

### B. 自动审查与摘要

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-010 | 打开 PR 自动触发审查 | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) / [PR](https://github.com/CodesSentinels/ai-reviewer-test/pull/300) | - | 2026-10-08 | 日志 eventKind=pr_opened；run 创建于 PR 创建 6 秒后 |
| FT-011 | synchronize/push 触发审查 | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37745413862) | - | 2026-10-08 | pr_synchronize 事件触发（pull_request，已固定 SHA 的 workflow）；日志 eventKind=pr_synchronize，Will review from commit 4c47d40a（增量） |
| FT-012 | reopened 触发审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-013 | 生成唯一顶部摘要 | external-observation | e2e | yes | no | PASS | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | PR 上仅 1 条 bot 摘要评论 |
| FT-014 | 后续审查更新既有摘要 | external-observation | e2e | yes | no | PASS | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37753470889) | - | 2026-10-08 | 同一条摘要评论被固定 SHA 的 full review 就地更新（updated 09:00:12），PR 上仍只有 1 条 Walkthrough 评论 |
| FT-015 | 摘要包含 Walkthrough | external-observation | e2e | yes | no | PASS | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | 摘要含 Walkthrough |
| FT-016 | 摘要包含 Changes 表格 | external-observation | e2e | yes | no | PASS | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | 摘要含 Changes 表格 |
| FT-017 | 相似文件合理合并 | external-observation | e2e | yes | no | PASS | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | Changes 表把 FT-001~FT-024 等同类用例文件合并为区间行 |
| FT-018 | 正确生成发布说明 | external-observation | e2e | yes | no | PASS | [PR](https://github.com/CodesSentinels/ai-reviewer-test/pull/300) | - | 2026-10-08 | PR 描述含 release-notes 区块（Summary by CodeSentinel，3 条要点） |
| FT-019 | 发布说明写入预期位置 | external-observation | e2e | yes | no | SUBMITTED | [PR](https://github.com/CodesSentinels/ai-reviewer-test/pull/300) | - | 2026-10-08 | release-notes 已写入 PR 描述；原描述为空，无法验证“原描述仍在”，待非空描述补测 |
| FT-020 | disable_release_notes 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-021 | disable_review 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-022 | language=zh-CN 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-023 | bot_icon 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-024 | bot_name 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### C. 行级评论与质量

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-030 | 识别明确逻辑错误 | fixture | e2e | yes | no | PASS | [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4217282218) / [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056947466) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37757357236) | - | 2026-10-08 | 固定 SHA 的 full review：pricing.ts 11-17 发布 🔴严重评论，指出 `i < items.length - 1` 漏掉最后一项并给出修复 diff（折扣符号问题未在该评论中提及） |
| FT-031 | 识别明确安全问题 | fixture | e2e | yes | no | PASS | [评论1](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4216981092) / [评论2](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4216981106) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37753470889) | - | 2026-10-08 | session.ts：SQL 拼接注入（🔴严重）、`==` 宽松相等；XSS 拼接另有 finding 但被 dedupe 跳过 |
| FT-032 | 识别明显性能问题 | fixture | e2e | yes | no | PASS | [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4217282232) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4217282269) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37757357236) | - | 2026-10-08 | 两条性能评论：aggregate.ts:26-31 循环内重复排序（🔴）、aggregate.ts:6-23 totalsBySku 的 O(n²) 多次扫描（🟡） |
| FT-033 | 评论位于实际变更行 | fixture | e2e | yes | no | PASS | [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4216981092) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4216981116) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4216981127) | - | 2026-10-08 | 本轮 4 条行级评论均落在新增文件的实际缺陷行范围内，failed: 0（新增文件场景，未变更行对照见 FT-034） |
| FT-034 | 不评论不存在或未变更行 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033704) | - | 2026-10-09 | Phase 2 的 6 条评论全部落在本次 diff 内；旧缺陷行（inventory.ts reserve、pricing.ts 折扣符号）未被重复评论 |
| FT-035 | 建议代码格式正确 | fixture | e2e | yes | no | PASS | [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4216981092) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4216981106) | - | 2026-10-08 | 修复建议为 <details> 内格式正确的 diff 代码块 |
| FT-036 | 默认忽略轻微样式问题 | fixture | e2e | yes | no | FAIL | [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033711) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [缺陷 #301](https://github.com/CodesSentinels/ai-reviewer-test/issues/301) | [#301](https://github.com/CodesSentinels/ai-reviewer-test/issues/301) | 2026-10-09 | Phase 2 仅格式化改动：nits.ts triage 为 NEEDS_REVIEW（预期 APPROVED）并收到 🔴严重评论，评论称“新增的命名”但 diff 无命名变化；缺陷 #301，状态 WAITING_FOR_FIX |
| FT-037 | review_simple_changes=true 生效 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-038 | review_comment_lgtm=false 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-039 | review_comment_lgtm=true 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-040 | 非法模型输出安全处理 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |

### D. 增量、全量与幂等

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-050 | 首次审查覆盖 base 到 HEAD | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) / [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | PatchScan 270 个文件；已审查 marker=4c47d40a（PR head） |
| FT-051 | 第二个 commit 仅审查新增变化 | multi-phase | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033704) | - | 2026-10-09 | pull_request run：Will review from commit 3ab89ae5（上次已审查）；只有 Phase 2 的 8 个文件进入审查，评论只落在新增行（inventory.ts 9-14），旧的 reserve 缺陷未重复评论 |
| FT-052 | 已审查 commit 状态正确保存 | multi-phase | e2e | yes | no | PASS | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | commit-ids-reviewed marker 累计保存 4c47d40a、70a69dff、803b07c9、bc29e49c；Phase 2 增量复核仍待 FT-051 |
| FT-053 | 重跑相同 workflow 不重复发布 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-054 | 重复事件不重复执行完整审查 | external-observation | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056667599) / [回复](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056673686) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37755374749) | - | 2026-10-08 | 同一 HEAD（bc29e49）再次 full review：回复 No new changes detected since the last review；run 约 27 秒，日志 summarize/reviewing/submit 均为 0（未重复执行审查） |
| FT-055 | 相同 finding 不重复发布 | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37753470889) | - | 2026-10-08 | 日志 [submit-dedup] 对 session.ts:11-12、pricing.ts:11-17 报 existing unresolved bot comment found 并跳过；[full-review-dedup] 跳过 3 个 patch |
| FT-056 | 旧 HEAD 不覆盖新结果 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-057 | 陈旧事件安全跳过 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-058 | 修改回退后状态一致 | multi-phase | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | revert/rules.ts 是第 31 个变更文件，被 #302 丢弃，未被审查；需 full review 取证 |
| FT-059 | full review 执行全量审查 | manual-command | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056404288) / [回复](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056409306) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37753470889) | - | 2026-10-08 | 日志 Will review full diff from the base commit: 8e0f9177，审查 18 个文件，dispatcher outcome executed/ok:true，bot 回复 Full review finished |
| FT-060 | summary 只重建摘要 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-061 | 部分评论失败时状态可解释 | manual-command | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-062 | 异常以失败状态退出 | external-observation | unit-evidence | yes | no | NOT_READY | - | - | 2026-10-08 | |

### E. 过滤、限制与忽略

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-070 | `@ai-reviewer: ignore` 跳过审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-071 | 移除 ignore 后恢复审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-072 | path_filters 包含规则生效 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 日志：kept.ts（匹配 **/*.ts）被审查；notes.txt（不在包含列表）checking path => false 被跳过 |
| FT-073 | path_filters 排除规则生效 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 日志：filtered/deps.lock checking path => false（被 `!**/*.lock` 排除） |
| FT-074 | dist 默认排除 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 基线 `!dist/**` 只匹配根目录 dist，workspace/dist/output.js 仍被审查并收到评论；需 no-path-filters 变体验证默认排除 |
| FT-075 | generated 默认排除 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 基线 path_filters 是自定义的，generated/api.generated.ts 被审查；需 no-path-filters 变体验证默认排除 |
| FT-076 | 二进制和图片默认排除 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | pixel.png 被跳过，但原因是不在基线包含列表；需 no-path-filters 变体验证“二进制默认排除” |
| FT-077 | max_files 生效 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 本次增量只处理了 30/62 个文件（见缺陷 #302），无法验证 max_files；变体 max-files(10) 待缺陷修复或改用 full review 路径 |
| FT-078 | 超大 diff 安全处理 | fixture | e2e | yes | no | FAIL | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) / [缺陷 #302](https://github.com/CodesSentinels/ai-reviewer-test/issues/302) | [#302](https://github.com/CodesSentinels/ai-reviewer-test/issues/302) | 2026-10-09 | 本次 push 改动 62 个文件，增量审查只处理 compare 列表的前 30 个，其余 32 个被静默丢弃，无任何提示，且 HEAD 仍记为已审查；缺陷 #302（单个 725 行大文件 large-module.ts 本身处理正常，3 处缺陷全部命中） |
| FT-079 | 新增文件处理正确 | multi-phase | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) | - | 2026-10-09 | new-file.ts：triage NEEDS_REVIEW，已审查，无误报评论 |
| FT-080 | 删除文件处理正确 | multi-phase | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) | - | 2026-10-09 | legacy.ts、old-name.ts 被删除：PatchScan 只含 8 个文件，删除文件被跳过，run 成功、无评论、无报错（摘要是否体现删除未核对） |
| FT-081 | 重命名文件处理正确 | multi-phase | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | GitHub compare 显示 final-name.ts status=renamed（previous=renamed.ts，内容 100% 相同）；bot 没有对它做摘要/审查/评论（无内容改动），run 成功 |
| FT-082 | 空 diff 不产生垃圾评论 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### F. 噪音控制

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-090 | max_review_comments 生效 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) / [Review](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#pullrequestreview-5453143957) | - | 2026-10-08 | max_review_comments=20：57 条 finding → 发布 20、截断 37（默认值下观察；变体 5 仍可补测） |
| FT-091 | 超限时优先保留高严重度问题 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | noise/many-issues.ts 被 #302 丢弃，未触发噪音控制；需 full review 取证 |
| FT-092 | 截断后不重复评论 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 同 FT-091 |
| FT-093 | 相似 finding 正确去重 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 同 FT-091 |
| FT-094 | 摘要与评论数量合理 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | 同 FT-091；此前 Phase 1 的摘要 + 评论数量合理性也待补 |
| FT-095 | 简单改动不产生大量噪音 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | greeter.ts 只加了一行文档注释：triage 为 APPROVED，没有评论 |

### G. 命令系统

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-100 | `@ai-reviewer help` | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-101 | `@codesentinel help` | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-102 | 真实 bot login 可触发命令 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-103 | configuration | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-104 | review | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-105 | full review | manual-command | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056404288) / [回复](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056409306) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37753470889) | - | 2026-10-08 | 同 FT-059（由 PR 作者 linfei0211 发布，该账号同时是仓库 ADMIN） |
| FT-106 | summary | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-107 | pause | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-108 | pause 后不自动审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-109 | resume | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-110 | resume 后恢复审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-111 | 重复 pause 幂等 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-112 | 重复 resume 幂等 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-113 | resolve | manual-command | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056625166) / [回复](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056631257) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37755064137) | - | 2026-10-08 | 固定 SHA 的 run（ref 8c84f45f…）执行成功：回复“已解决 43 条”，GraphQL 复核该 PR 43/43 线程 resolved、0 unresolved；未配置 resolve_token 即成功；命令评论上有 rocket reaction |
| FT-114 | resolve 只解决 bot thread | manual-command | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6072861905) / [回复](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6072866282) / [真人线程](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4225985381) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37873621471) | - | 2026-10-09 | 固定 SHA 的 run：回复“已解决 8 条”；GraphQL 复核 PR 共 45 个线程，44 个 resolved 且全部是 bot 线程，bot 线程 0 个未解决 |
| FT-115 | resolve 不解决真人 thread | manual-command | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6072861905) / [回复](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6072866282) / [真人线程](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4225985381) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37873621471) | - | 2026-10-09 | 真人（linfei0211）在 pricing.ts:11 的线程 resolve 后仍为 unresolved，且线程里只有这 1 条真人评论 |
| FT-116 | 命令 ack reaction 生效 | external-observation | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056404288) | - | 2026-10-08 | bot 在命令评论上 08:59:06 添加 rocket reaction（早于回复） |
| FT-117 | reaction 关闭配置生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-118 | 相同评论只执行一次 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-119 | 未知英文命令返回帮助 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-120 | 自然语言进入对话 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-121 | 命令大小写不敏感 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-122 | 邮箱内 mention 不误触发 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-123 | 相似用户名不误触发 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-124 | 过长命令被拒绝 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-125 | 参数数量超限被拒绝 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-126 | 单参数过长被拒绝 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-127 | Shell 元字符被拒绝 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-128 | 速率限制生效 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-129 | 顶层评论支持命令 | manual-command | e2e | yes | no | PASS | [命令评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056404288) / [回复](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6056409306) | - | 2026-10-08 | 顶层评论 `@ai-reviewer full review` 被识别并执行 |
| FT-130 | 行级 thread 支持命令 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### H. 权限模型

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-140 | PR 作者可执行 review | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-141 | PR 作者可执行 full review | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-142 | PR 作者可执行 summary | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-143 | 作者豁免不适用于 pause | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-144 | 作者豁免不适用于 resume | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-145 | 作者豁免不适用于 resolve | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-146 | write 用户可执行受限命令 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-147 | triage 用户可执行 configuration | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-148 | read 用户可执行 help | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-149 | 无权限用户被拒绝 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-150 | 权限查询失败时 fail closed | external-observation | unit-evidence | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-151 | GitHub 权限术语正确 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-152 | GitLab权限术语正确 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### I. 对话追问

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-160 | 回复 bot 行级评论时结合 diff 回答 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-161 | 非 bot thread 显式 mention 可回答 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-162 | 无 mention 时不误回复 | manual-command | e2e | yes | no | PASS | [真人线程](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4225985381) / [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37873586079) | - | 2026-10-09 | 真人行级评论无 @bot：run 日志 dispatcher outcome ignored（reason: no bot mention），线程内无 bot 回复 |
| FT-163 | bot 自评论不触发回复 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-164 | 多轮对话保留上下文 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-165 | 长评论链安全截断 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-166 | 顶层自然语言提问行为正确 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-167 | 不声称读取不可用内容 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-168 | 重复 webhook 不重复回答 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### J. 跨文件依赖

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-170 | 识别导出函数签名变化 | multi-phase | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033719) | - | 2026-10-09 | formatter.ts:8-14 🔴评论：指出返回值 string→{text,total}、新增必填参数，并列出 5 个受影响调用方 |
| FT-171 | 识别返回语义变化 | multi-phase | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033719) | - | 2026-10-09 | 同一评论指出返回语义变化（依赖字符串的地方需改读 text） |
| FT-172 | 支持相对路径导入 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033719) | - | 2026-10-09 | summary.ts:5 的相对路径导入（../shared/formatter）被列为受影响调用方 |
| FT-173 | 支持别名导入 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033719) | - | 2026-10-09 | alias-user.ts:5 的别名导入（~/functional-tests/…）被列为受影响调用方 |
| FT-174 | 支持目录 index 导入 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033719) | - | 2026-10-09 | index-user.ts:5 的目录 index 导入（../shared）被列为受影响调用方，shared/index.ts 作为 barrel 也被识别 |
| FT-175 | 关闭依赖分析后安全降级 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-176 | max_dependency_files 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-177 | 无法解析依赖时安全降级 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | - | 2026-10-09 | unresolved/importer.ts 被 #302 丢弃，未被审查；需 full review 取证 |
| FT-178 | 仓库树缓存不跨 PR 污染 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-179 | 当前技术栈依赖分析正确 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033719) | - | 2026-10-09 | Vue SFC OrderCard.vue:7 作为调用方被识别（依赖分析 step 6：6 个文件分析、5 处跨文件引用） |

### K. Web Search 与 Shell

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-180 | enable_web_search=true 生效 | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | enable_web_search=true：日志 [web_search] executed ×191 |
| FT-181 | enable_web_search=false 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-182 | 搜索失败后安全降级 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-183 | enable_shell=false 时不执行 shell | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | enable_shell=false：日志无任何 shell 执行记录 |
| FT-184 | shell=true 只在隔离无密钥环境测试 | manual-security | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-185 | shell 具有超时和输出限制 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-186 | shell 输出脱敏 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-187 | PR 内容不能诱导读取环境变量 | fixture | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-188 | PR 内容不能诱导读取凭据目录 | fixture | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |

### L. Lint 与 SAST

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-190 | enable_lint_tools=false 生效 | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 日志 Phase 0b: lint tools disabled by config；enable_semgrep:true 随总开关不生效，无疑似缺陷 |
| FT-191 | ESLint 有配置时发现问题 | fixture | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-192 | ESLint 无配置时安全降级 | fixture | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-193 | Biome 返回结构化结果 | fixture | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-194 | tsc 有 tsconfig 时运行 | fixture | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-195 | tsc 无配置时安全降级 | fixture | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-196 | Prettier 默认关闭 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-197 | 显式开启 Prettier 后生效 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-198 | Semgrep 默认关闭 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-199 | 显式开启 Semgrep 后生效 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-200 | semgrep_config 生效 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-201 | 工具版本覆盖生效 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-202 | 工具安装失败安全降级 | external-observation | e2e | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-203 | 工具超时安全处理 | external-observation | unit-evidence | no | yes | NOT_READY | - | - | 2026-10-08 | |
| FT-204 | 外部 lint_report_path 可读取 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-205 | 畸形报告顶层被拒绝 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-206 | 绝对路径 finding 被丢弃 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-207 | `..` 路径被丢弃 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-208 | 非法 severity 被丢弃 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-209 | 非法行列号被丢弃 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-210 | 超量 finding 被截断 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-211 | lint 提示词注入无效 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-212 | lint 与 AI finding 去重 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-213 | 持密钥 job 不执行 PR 代码 | manual-security | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 基线观察：持密钥 job 检出 PR merge commit（eb10f70 = Merge 4c47d40a into 8e0f917）；待用户判定是否为缺陷 |

### M. 错误与重试

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-220 | OpenAI 429 重试 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-221 | OpenAI 5xx 重试 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-222 | OpenAI 超时正确处理 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-223 | 空响应安全处理 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-224 | 非法 JSON 安全处理 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-225 | Markdown 包裹输出正确处理 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-226 | GitHub API 暂时失败时重试 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-227 | GitLab API 暂时失败时重试 | external-gitlab | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-228 | 部分评论失败不破坏全部结果 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-229 | uncaughtException 导致任务失败 | external-observation | unit-evidence | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-230 | unhandledRejection 导致任务失败 | external-observation | unit-evidence | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-231 | 日志不包含 Authorization header | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 日志无 Authorization 头（正则命中 0） |
| FT-232 | 日志不包含 Token 或 API Key | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 日志无 token/API key 形态字符串（ghs_/ghp_/sk-/glpat- 等命中 0） |
| FT-233 | 日志不包含敏感 URL 参数 | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 日志无敏感 URL 参数（token/access_token/api_key/key 命中 0） |

### N. Fork 与安全

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-240 | fork PR 不在持密钥 job 执行代码 | manual-security | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-241 | fork 无法通过 workflow 修改获取 Secret | manual-security | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-242 | fork artifact 被视为不可信数据 | manual-security | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-243 | 恶意 PR 标题不能覆盖系统提示 | manual-security | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-244 | 恶意 PR 描述不能覆盖系统提示 | manual-security | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-245 | 恶意代码注释不能覆盖系统提示 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226124208) | - | 2026-10-09 | 无泄密：已发布评论中没有环境变量、token 占位符；其他文件仍正常给出严重评论。但 comment-injection.ts 自己没有评论（其缺陷只是 parseInt 缺 radix，较弱），无法区分是注入起效还是本就无 finding；建议加强该夹具（加入明显缺陷）后复测 |
| FT-246 | 恶意文件名不能突破路径边界 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) / [评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226124208) | - | 2026-10-09 | 文件名含空格与分号的 `name with space;semi.ts` 被当作普通路径处理：日志正常 reviewing，无报错、无路径越界；（该文件的除零缺陷本次未被评论，不影响路径边界判定） |
| FT-247 | 恶意 lint message 不能泄密 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-248 | bot 自评论不形成循环 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-249 | 重复 webhook 不形成循环 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-250 | 日志无 OPENAI_API_KEY | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | OPENAI_API_KEY 仅以变量名出现，值为 *** |
| FT-251 | 日志无 GITHUB_TOKEN | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | GITHUB_TOKEN 仅以变量名出现，值为 *** |
| FT-252 | 日志无 GITLAB_PAT | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-253 | 双平台状态 marker 独立 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### O. GitLab 专项

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-260 | MR open 触发审查 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-261 | MR push 触发增量审查 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-262 | MR reopen 触发审查 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-263 | merge/close 不误触发 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-264 | 顶层 Note 进入命令路径 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-265 | diff discussion 进入行级路径 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-266 | 非 MR note 被忽略 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-267 | system note 被忽略 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-268 | 非 create note 被忽略 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-269 | 缺 project.id 时 fail closed | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-270 | 缺 MR iid 时 fail closed | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-271 | 缺 last_commit.id 时 fail closed | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-272 | 未知 object_kind 安全跳过 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-273 | fork MR fail closed | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-274 | 陈旧 MR HEAD 被跳过 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-275 | 相同 headSha 只审查一次 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-276 | 相同 note ID 只执行一次 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-277 | bot 身份不一致时告警 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-278 | subgroup 路径解析正确 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-279 | PAT 身份与权限正确 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-280 | CI_JOB_TOKEN 限制有明确诊断 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-281 | GitLab API host 校验正确 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-282 | GitLab diff 定位正确 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-283 | GitLab 帮助术语正确 | external-gitlab | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### P. 性能、成本和可观测性

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-290 | 记录小 PR 执行时间 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-291 | 记录中等 PR 执行时间 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-292 | 记录大 PR 执行时间 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-293 | 记录 light model 调用数量 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-294 | 记录 heavy model 调用数量 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-295 | 记录平台 API 调用情况 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-296 | OpenAI 并发限制生效 | external-observation | unit-evidence | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-297 | GitHub API 并发限制生效 | external-observation | unit-evidence | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-298 | 重复事件不重复产生模型费用 | external-observation | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37755374749) | - | 2026-10-08 | 日志显示该次重复命令没有任何摘要/审查/web_search 调用；缺 OpenAI 用量面板数据，不据此判 PASS |
| FT-299 | 日志可区分各执行阶段 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-300 | 最终报告包含发布建议 | local-validation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

## 缺陷清单

| 缺陷 Issue | FT | ai-reviewer SHA | 失败 commit | 首次失败证据 | 状态 |
|---|---|---|---|---|---|
| [#302](https://github.com/CodesSentinels/ai-reviewer-test/issues/302) | FT-078 | `8c84f45f` | `88bf7db4` | [run 37875759051](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051) | WAITING_FOR_FIX |
| [#301](https://github.com/CodesSentinels/ai-reviewer-test/issues/301) | FT-036 | `8c84f45f` | `83140bc0` | [run 37874287998](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998)、[评论 r4226033711](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#discussion_r4226033711) | WAITING_FOR_FIX |

（失败行永不删除，修复后追加 RETEST 记录。）

## 阻塞与待用户事项

- 隔离环境（shell-on-isolated / lint-on-isolated）：待用户回答。未提供时，以下 FT 保持 BLOCKED：FT-184, FT-185, FT-186, FT-187, FT-188, FT-191, FT-192, FT-193, FT-194, FT-195, FT-196, FT-197, FT-198, FT-199, FT-200, FT-201, FT-202, FT-203。
- 多账号 / fork / GitLab：FT-102、FT-140~150（需要 write / triage / read / 无权限账号）、FT-240~242（fork 账号）、FT-152、FT-227、FT-252、FT-253、FT-260~283（GitLab Runner 与 PAT）缺少前置时标 BLOCKED。
- 故障注入 / 单测证据：coverage 为 needs-injection 或 unit-evidence 的 FT（见总表）无法靠常规 PR 复现，取不到证据时标 N/A 并写明理由。

## 待确认差异

基线偏差表（只报告，不自行修改，请用户逐项确认）：

| 现状 | 影响的 FT | 处理 |
|---|---|---|
| `debug: true` | FT-007（debug=false）需要变体；FT-008 可用基线 | 变体 `debug-off` |
| `enable_web_search: true` | FT-181（false）需要变体 | 变体 `web-search-off` |
| `setup-node` 的 `node-version: "20"` | FT-004 要求 Node 24 | ai-reviewer 的 `action.yml` 为 `runs.using: node24`，action 运行时与 job 的 Node 版本无关；以运行日志为证，无需变体 |
| `enable_semgrep: true` | 总开关 `enable_lint_tools=false` 时预期不生效 | 已确认：日志 `Phase 0b: lint tools disabled by config, skipping`，无疑似缺陷（FT-190 PASS） |
| `debug_resolve_inject_failures: "3"` | 原以为可用于 FT-061 | 已查源码：锁定 SHA 的 `resolve.ts` 注入代码已被注释，该输入不生效；FT-061 改为 needs-injection（需构造真实的部分失败，否则 N/A） |
| 持密钥 job 内 `actions/checkout@v4` 在 pull_request 事件下检出 PR 代码 | FT-213、FT-240 | 已证实：run 日志 HEAD 为 `eb10f70 Merge 4c47d40a into 8e0f917`；基线观察项，由用户决定是否判缺陷；不自行修改 |
| `push` 触发含 `test/dev*`，新分支名不匹配 | FT-011 | 本轮只靠 pull_request 触发，FT-011 以 PR synchronize 为准 |
| 项目 CLAUDE.md 原有说明（“动态解析分支”“开启 shell/lint”）已与本轮基线不一致 | 无 | 仅追加续作区块，原文未改动；请按需自行更新 |
| **评论类事件使用默认分支 workflow**（本次新增） | 全部命令类用例（G/H/I 分区、FT-014/052/059/060/061/105/106 等） | 已证实：[run 37745545033](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37745545033) 的 ai-reviewer ref 为 `main`、shell/lint 为 true；需先把基线 workflow 合入 main，见“下一步” |
| Phase 2 的 pricing.ts 评论把循环边界修复称为“逻辑回归”；inventory.ts 只评论 snapshot、未指出 release 不校验数量（本次新增） | FT-030、FT-051 | 评论质量观察项，不影响 PASS 判定 |
| 纯样式/lint 类问题被标为 🔴严重 | FT-091、FT-094，间接影响 FT-036 | 观察项：nits.ts、lint-issues.ts 的评论均为严重；提示词里 `nit` 定义为 trivial improvements。是否记为缺陷由用户决定，Phase 2/3 再收集更多样本 |
| 首轮 run 的 max_files 截断 | FT-030~036、FT-091、FT-094 等 | 测试设计问题；已决定：`path_filters` 删除 `**/*.md`（基线第 4 处改动，已修改未提交），再用 full review 重审 |
| PR 内导入扫描漏掉“同为新增且有导出”的导入方（本次新增） | FT-172~174、FT-179 | 源码依据：`dependency-analyzer.ts` step 2 的 prCandidates 排除 allModifiedSymbols；Phase 2 复测后再判定是否为缺陷 |
| Phase 1 提交包含脚本维护文件 `.cases-prepared`、`.managed-files`、`.phase-1-generated` | 无 | 属于夹具目录的一部分，保留提交即可；不要手改 |
| lint 夹具与 Biome 范围 | FT-193 | Biome 仅覆盖 `utils/**`、`composables/**`，需用户在这两个目录手动放一个带问题的 `.ts` 文件（夹具目录不在范围内） |
| `lint-issues.ts`、`tsc-issue.ts` 故意不可编译/不规范 | 无 | 仅是夹具，不参与 nuxt 构建 |

## 变更日志（倒序，只追加）

- 2026-10-09T03:40:00Z：用户提交并推送 Phase 3（88bf7db）。读取 [run 37875759051](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37875759051)：增量审查（Will review from 83140bc0）只处理 compare 列表的前 30/62 个文件，28 个 many/、noise/、revert/、unresolved/ 被静默丢弃且 HEAD 仍记为已审查；根因为 `compareDiff` 的 `compareCommits` 未分页。新增 PASS 5 项（FT-072/073/081/095/246），FT-078 FAIL，创建缺陷 [#302](https://github.com/CodesSentinels/ai-reviewer-test/issues/302)，11 项待 full review 补取证。原因：用户提供 run 链接。
- 2026-10-09T03:10:00Z：用户提交 Phase 2（83140bc0）。读取 [run 37874287998](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37874287998)（pull_request / pr_synchronize，固定 SHA，Will review from 3ab89ae5，8 个文件，delivered 6）：新增 PASS 10 项（FT-034/051/079/080/170/171/172/173/174/179）；FT-036 FAIL，创建缺陷 [#301](https://github.com/CodesSentinels/ai-reviewer-test/issues/301)；FT-081 因 GitHub 未识别为重命名保持 SUBMITTED，Phase 3 增加 100% 相同内容的重命名；原因：用户提供 run 链接。
- 2026-10-09T02:30:00Z：用户在 PR 上发了真人行级评论（pricing.ts:11）并再次执行 resolve。读取 [run 37873621471](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37873621471)、[run 37873586079](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37873586079)：resolve 回复“已解决 8 条”，GraphQL 复核 45 个线程中 44 个已 resolved（均为 bot），真人线程仍 unresolved；真人评论无 mention 被 ignored。FT-114/115/162 PASS。原因：用户反馈 resolve 结果并询问是否先提交文档。
- 2026-10-08T10:15:00Z：用户提交 3ab89ae 后第五次发布 full review，读取 [run 37757357236](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37757357236)：ref 8c84f45f…、full diff 审查 18 个文件、发布 8 条评论；FT-030 PASS，FT-032 复核 PASS；FT-036 因 nits.ts 是新增文件不是有效探针，给 `generate_style_nit` 增加 Phase 2 仅格式化改动（脚本、case-map、FT-036/037 用例已更新）；记录严重度偏高观察项。原因：用户提供 run 链接。
- 2026-10-08T09:50:00Z：用户第四次发布 full review（截图：HEAD bc29e49 已审查，No new changes detected）。读取 [run 37755374749](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37755374749)：ref 8c84f45f…，摘要/审查/提交均为 0，约 27 秒。源码核对：`fullReviewHandler` 在 `isHeadAlreadyReviewed` 为真时直接返回，属设计行为；FT-054 PASS，FT-298 SUBMITTED（缺用量面板）。
- 2026-10-08T09:30:00Z：用户发布 `@ai-reviewer resolve`。读取 [run 37755064137](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37755064137)：ref 8c84f45f…，dispatcher executed/ok，回复已解决 43 条，GraphQL 复核 43/43 resolved；FT-113 PASS；FT-114/115 待真人线程。原因：用户贴出 bot 回复截图。
- 2026-10-08T09:40:00Z：用户询问 resolve 怎么执行。核对锁定 SHA 的 `resolve.ts`：对全部未解决 bot 线程批量处理、需 write 权限；`debug_resolve_inject_failures` 的注入代码已被注释，不生效。修正此前“resolve 输出带 failed=3”的错误预期，FT-061 改为 needs-injection；同步更新 FT-061 用例、no-resolve-inject / baseline 变体说明。
- 2026-10-08T09:20:00Z：用户把“固定 SHA”合入 main（67a9144）后第三次发布 full review。读取 [run 37753470889](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37753470889)：日志 ai-reviewer ref=8c84f45f…、shell/lint false、18 个文件、delivered 4；判定新增 PASS 11 项（FT-014/031/032/033/035/052/055/059/105/116/129），FT-030/034/036 与 FT-172~174/179 更新备注保持 SUBMITTED；原因：用户报告 full review 执行完。
- 2026-10-08T09:00:00Z：用户把基线部分合入 main（commit eff0435：shell/lint 关闭、删除 md）后第二次发布 full review。读取 [run 37752372756](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37752372756)：success，但日志 `BRANCH="main"`、`ref: main`，ai-reviewer 取的是 main 分支而非锁定 SHA（main 的 workflow 仍有 Resolve ai-reviewer branch 步骤）；因此不作为 develop 证据。参考性观察：该 run 审查了 17 个文件，包含 workspace 夹具，delivered 9 条评论（session.ts、pricing.ts、aggregate.ts、inventory.ts、lint 文件、nits.ts 等），说明 md 排除后夹具能进入审查范围；PR 另有 commit 803b07c9（pull_request 事件的 run 37752133346 成功，使用 PR 的 workflow）。原因：用户报告 full review 执行完。
- 2026-10-08T08:30:00Z：用户推送 commit 70a69dff（删除 `**/*.md`）并在 PR 评论 `@ai-reviewer full review`。读取两个 run：[37745413862](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37745413862)（pull_request / synchronize，固定 SHA，只含被排除路径→跳过，FT-011 PASS）、[37745545033](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37745545033)（issue_comment，用了 main 的旧 workflow：ai-reviewer main、shell/lint true、md 仍审查，delivered 10 条评论，本地 shell 被执行）。后者不作为 develop 证据；原因：用户报告 full review 执行完。
- 2026-10-08T08:05:00Z：用户决定 md 文档不审查；在 `ai-reviewer.yml` 的 `path_filters` 删除 `**/*.md`（基线第 4 处改动，未提交），同步更新 baseline.md / README / 报告模板；原因：首轮 run 因 max_files=150 截断，workspace 夹具未被审查。
- 2026-10-08T07:45:00Z：读取 PR #300 首轮 run（37742626690，约 6m14s，成功）。判定 PASS 22 项、SUBMITTED 17 项；发现 max_files=150 截断导致 workspace 夹具未被审查（测试设计问题）；更新 Issue #299；原因：用户提供 PR URL。
- 2026-10-08T07:10:00Z：第一阶段准备完成：解析 SHA、创建分支/脚本/映射/变体/README/报告模板/进度文档，按基线修改 workflow（未提交）；原因：用户要求开工。
