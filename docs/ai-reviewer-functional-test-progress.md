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
- current_stage: PHASE1_SUBMITTED
- last_updated: 2026-10-08T08:30:00Z
- last_updated_by_step: 读取 full review 的 run：发现评论类事件用了 main 的 workflow，结果不能作为 develop SHA 证据；FT-011 PASS；等待用户把基线 workflow 合入 main

## 下一步（Next Actions）

1. 用户：把基线 workflow 合入 `main`。原因：`issue_comment` / `pull_request_review_comment` 事件使用默认分支（main）的 workflow，上一次 `@ai-reviewer full review` 实际跑的是 main 的旧配置（ai-reviewer 取 main 分支、shell/lint 开启、md 仍被审查），不能作为 develop SHA 的证据。做法：另开一个只改 `.github/workflows/ai-reviewer.yml` 的小 PR（固定 SHA、shell=false、lint=false、删除 `**/*.md`）合入 main。完成判定：`main` 上的 ai-reviewer.yml 含锁定 SHA。
2. 用户：合入后在 PR #300 重新发布 `@ai-reviewer full review`（同时覆盖 FT-059 / FT-105），等 run 完成后把链接发给 Claude。注意先确认该 run 的 headSha 是 main 的新提交，且日志里 ai-reviewer 的 checkout ref 为锁定 SHA。
3. Claude：读取该 run，重新判定 FT-030~036、FT-091、FT-094、FT-172~174、FT-179、FT-014、FT-052、FT-059、FT-105 等（预期可审查文件约 30 个，不再被 max_files 截断）。
4. 用户：Phase 1 重审通过后，`--phase 2 --dry-run` → `--phase 2` → 检查增量 diff → 提交推送 → 把 commit / run 链接发给 Claude。
5. 用户（可并行）：确认基线偏差表，回答是否提供隔离环境。

## 阶段与运行记录

| 阶段/变体 | 分支 | Commit SHA | PR | Workflow | 时间 | 状态 |
|---|---|---|---|---|---|---|
| Phase 1 | `test/ai-reviewer-develop-functional-20261008` | `4c47d40a` | [#300](https://github.com/CodesSentinels/ai-reviewer-test/pull/300) | [run 37742626690](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | 2026-10-08T07:18Z（耗时约 6m14s） | SUBMITTED |
| Phase 2 | `test/ai-reviewer-develop-functional-20261008` | 待填写 | 同一 PR | 待填写 | 待填写 | NOT_READY |
| Phase 3 | `test/ai-reviewer-develop-functional-20261008` | 待填写 | 同一 PR | 待填写 | 待填写 | NOT_READY |

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

汇总：共 226 项；PASS 23 / FAIL 0 / BLOCKED 0 / N/A 0 / 其余 203（NOT_READY 186、SUBMITTED 17）。

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
| FT-014 | 后续审查更新既有摘要 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
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
| FT-030 | 识别明确逻辑错误 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | workspace 夹具未被审查：270 个可审查文件 > max_files=150，按路径排序 workspace 排在 cases 之后被截断，需调整过滤后 full review 重跑 |
| FT-031 | 识别明确安全问题 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | workspace 夹具未被审查：270 个可审查文件 > max_files=150，按路径排序 workspace 排在 cases 之后被截断，需调整过滤后 full review 重跑 |
| FT-032 | 识别明显性能问题 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | workspace 夹具未被审查：270 个可审查文件 > max_files=150，按路径排序 workspace 排在 cases 之后被截断，需调整过滤后 full review 重跑 |
| FT-033 | 评论位于实际变更行 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | workspace 夹具未被审查：270 个可审查文件 > max_files=150，按路径排序 workspace 排在 cases 之后被截断，需调整过滤后 full review 重跑 |
| FT-034 | 不评论不存在或未变更行 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | workspace 夹具未被审查：270 个可审查文件 > max_files=150，按路径排序 workspace 排在 cases 之后被截断，需调整过滤后 full review 重跑 |
| FT-035 | 建议代码格式正确 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | workspace 夹具未被审查：270 个可审查文件 > max_files=150，按路径排序 workspace 排在 cases 之后被截断，需调整过滤后 full review 重跑 |
| FT-036 | 默认忽略轻微样式问题 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | workspace 夹具未被审查：270 个可审查文件 > max_files=150，按路径排序 workspace 排在 cases 之后被截断，需调整过滤后 full review 重跑 |
| FT-037 | review_simple_changes=true 生效 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-038 | review_comment_lgtm=false 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-039 | review_comment_lgtm=true 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-040 | 非法模型输出安全处理 | external-observation | needs-injection | yes | no | NOT_READY | - | - | 2026-10-08 | |

### D. 增量、全量与幂等

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-050 | 首次审查覆盖 base 到 HEAD | external-observation | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) / [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | PatchScan 270 个文件；已审查 marker=4c47d40a（PR head） |
| FT-051 | 第二个 commit 仅审查新增变化 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-052 | 已审查 commit 状态正确保存 | multi-phase | e2e | yes | no | SUBMITTED | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) | - | 2026-10-08 | commit-ids-reviewed marker=4c47d40a 已保存；需 Phase 2 对比后判定 |
| FT-053 | 重跑相同 workflow 不重复发布 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-054 | 重复事件不重复执行完整审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-055 | 相同 finding 不重复发布 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-056 | 旧 HEAD 不覆盖新结果 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-057 | 陈旧事件安全跳过 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-058 | 修改回退后状态一致 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-059 | full review 执行全量审查 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-060 | summary 只重建摘要 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-061 | 部分评论失败时状态可解释 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-062 | 异常以失败状态退出 | external-observation | unit-evidence | yes | no | NOT_READY | - | - | 2026-10-08 | |

### E. 过滤、限制与忽略

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-070 | `@ai-reviewer: ignore` 跳过审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-071 | 移除 ignore 后恢复审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-072 | path_filters 包含规则生效 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-073 | path_filters 排除规则生效 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-074 | dist 默认排除 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-075 | generated 默认排除 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-076 | 二进制和图片默认排除 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-077 | max_files 生效 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 默认 max_files=150 已观察到 270→150；变体 max-files(10) 与 many/ 夹具未运行 |
| FT-078 | 超大 diff 安全处理 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-079 | 新增文件处理正确 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-080 | 删除文件处理正确 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-081 | 重命名文件处理正确 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-082 | 空 diff 不产生垃圾评论 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### F. 噪音控制

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-090 | max_review_comments 生效 | fixture | e2e | yes | no | PASS | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) / [Review](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#pullrequestreview-5453143957) | - | 2026-10-08 | max_review_comments=20：57 条 finding → 发布 20、截断 37（默认值下观察；变体 5 仍可补测） |
| FT-091 | 超限时优先保留高严重度问题 | fixture | e2e | yes | no | SUBMITTED | [Review](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#pullrequestreview-5453143957) | - | 2026-10-08 | 57→20；是否优先保留高严重度待核对 20 条评论的严重度 |
| FT-092 | 截断后不重复评论 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-093 | 相似 finding 正确去重 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-094 | 摘要与评论数量合理 | fixture | e2e | yes | no | SUBMITTED | [摘要评论](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#issuecomment-6054749546) / [Review](https://github.com/CodesSentinels/ai-reviewer-test/pull/300#pullrequestreview-5453143957) | - | 2026-10-08 | 摘要 + 20 条行级评论，合理性待核对 |
| FT-095 | 简单改动不产生大量噪音 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### G. 命令系统

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-100 | `@ai-reviewer help` | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-101 | `@codesentinel help` | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-102 | 真实 bot login 可触发命令 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-103 | configuration | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-104 | review | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-105 | full review | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-106 | summary | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-107 | pause | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-108 | pause 后不自动审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-109 | resume | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-110 | resume 后恢复审查 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-111 | 重复 pause 幂等 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-112 | 重复 resume 幂等 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-113 | resolve | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-114 | resolve 只解决 bot thread | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-115 | resolve 不解决真人 thread | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-116 | 命令 ack reaction 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
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
| FT-129 | 顶层评论支持命令 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
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
| FT-162 | 无 mention 时不误回复 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-163 | bot 自评论不触发回复 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-164 | 多轮对话保留上下文 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-165 | 长评论链安全截断 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-166 | 顶层自然语言提问行为正确 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-167 | 不声称读取不可用内容 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-168 | 重复 webhook 不重复回答 | manual-command | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

### J. 跨文件依赖

| FT | 标题 | type | coverage | baselineMeaningful | 隔离环境 | 状态 | 证据链接 | 缺陷 Issue | 最后更新 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-170 | 识别导出函数签名变化 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-171 | 识别返回语义变化 | multi-phase | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-172 | 支持相对路径导入 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 依赖分析仅发现 index.ts→formatter/types 的 2 条 PR 内导入；summary/alias-user/index-user/OrderCard 因同为新增且有导出，被排除在 PR 内导入扫描之外（dependency-analyzer.ts step 2）。Phase 2 导入方不再是修改文件，届时重新判定 |
| FT-173 | 支持别名导入 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 依赖分析仅发现 index.ts→formatter/types 的 2 条 PR 内导入；summary/alias-user/index-user/OrderCard 因同为新增且有导出，被排除在 PR 内导入扫描之外（dependency-analyzer.ts step 2）。Phase 2 导入方不再是修改文件，届时重新判定 |
| FT-174 | 支持目录 index 导入 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 依赖分析仅发现 index.ts→formatter/types 的 2 条 PR 内导入；summary/alias-user/index-user/OrderCard 因同为新增且有导出，被排除在 PR 内导入扫描之外（dependency-analyzer.ts step 2）。Phase 2 导入方不再是修改文件，届时重新判定 |
| FT-175 | 关闭依赖分析后安全降级 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-176 | max_dependency_files 生效 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-177 | 无法解析依赖时安全降级 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-178 | 仓库树缓存不跨 PR 污染 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-179 | 当前技术栈依赖分析正确 | fixture | e2e | yes | no | SUBMITTED | [Workflow](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37742626690) | - | 2026-10-08 | 依赖分析仅发现 index.ts→formatter/types 的 2 条 PR 内导入；summary/alias-user/index-user/OrderCard 因同为新增且有导出，被排除在 PR 内导入扫描之外（dependency-analyzer.ts step 2）。Phase 2 导入方不再是修改文件，届时重新判定 |

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
| FT-245 | 恶意代码注释不能覆盖系统提示 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-246 | 恶意文件名不能突破路径边界 | fixture | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
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
| FT-298 | 重复事件不重复产生模型费用 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-299 | 日志可区分各执行阶段 | external-observation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |
| FT-300 | 最终报告包含发布建议 | local-validation | e2e | yes | no | NOT_READY | - | - | 2026-10-08 | |

## 缺陷清单

暂无。（失败行永不删除，修复后追加 RETEST 记录。）

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
| `debug_resolve_inject_failures: "3"` | 可用于 FT-061；会让 FT-113~115 的 resolve 输出带 `failed=3` | 基线保留；被干扰时用变体 `no-resolve-inject` 重测 |
| 持密钥 job 内 `actions/checkout@v4` 在 pull_request 事件下检出 PR 代码 | FT-213、FT-240 | 已证实：run 日志 HEAD 为 `eb10f70 Merge 4c47d40a into 8e0f917`；基线观察项，由用户决定是否判缺陷；不自行修改 |
| `push` 触发含 `test/dev*`，新分支名不匹配 | FT-011 | 本轮只靠 pull_request 触发，FT-011 以 PR synchronize 为准 |
| 项目 CLAUDE.md 原有说明（“动态解析分支”“开启 shell/lint”）已与本轮基线不一致 | 无 | 仅追加续作区块，原文未改动；请按需自行更新 |
| **评论类事件使用默认分支 workflow**（本次新增） | 全部命令类用例（G/H/I 分区、FT-014/052/059/060/061/105/106 等） | 已证实：[run 37745545033](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37745545033) 的 ai-reviewer ref 为 `main`、shell/lint 为 true；需先把基线 workflow 合入 main，见“下一步” |
| 首轮 run 的 max_files 截断 | FT-030~036、FT-091、FT-094 等 | 测试设计问题；已决定：`path_filters` 删除 `**/*.md`（基线第 4 处改动，已修改未提交），再用 full review 重审 |
| PR 内导入扫描漏掉“同为新增且有导出”的导入方（本次新增） | FT-172~174、FT-179 | 源码依据：`dependency-analyzer.ts` step 2 的 prCandidates 排除 allModifiedSymbols；Phase 2 复测后再判定是否为缺陷 |
| Phase 1 提交包含脚本维护文件 `.cases-prepared`、`.managed-files`、`.phase-1-generated` | 无 | 属于夹具目录的一部分，保留提交即可；不要手改 |
| lint 夹具与 Biome 范围 | FT-193 | Biome 仅覆盖 `utils/**`、`composables/**`，需用户在这两个目录手动放一个带问题的 `.ts` 文件（夹具目录不在范围内） |
| `lint-issues.ts`、`tsc-issue.ts` 故意不可编译/不规范 | 无 | 仅是夹具，不参与 nuxt 构建 |

## 变更日志（倒序，只追加）

- 2026-10-08T08:30:00Z：用户推送 commit 70a69dff（删除 `**/*.md`）并在 PR 评论 `@ai-reviewer full review`。读取两个 run：[37745413862](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37745413862)（pull_request / synchronize，固定 SHA，只含被排除路径→跳过，FT-011 PASS）、[37745545033](https://github.com/CodesSentinels/ai-reviewer-test/actions/runs/37745545033)（issue_comment，用了 main 的旧 workflow：ai-reviewer main、shell/lint true、md 仍审查，delivered 10 条评论，本地 shell 被执行）。后者不作为 develop 证据；原因：用户报告 full review 执行完。
- 2026-10-08T08:05:00Z：用户决定 md 文档不审查；在 `ai-reviewer.yml` 的 `path_filters` 删除 `**/*.md`（基线第 4 处改动，未提交），同步更新 baseline.md / README / 报告模板；原因：首轮 run 因 max_files=150 截断，workspace 夹具未被审查。
- 2026-10-08T07:45:00Z：读取 PR #300 首轮 run（37742626690，约 6m14s，成功）。判定 PASS 22 项、SUBMITTED 17 项；发现 max_files=150 截断导致 workspace 夹具未被审查（测试设计问题）；更新 Issue #299；原因：用户提供 PR URL。
- 2026-10-08T07:10:00Z：第一阶段准备完成：解析 SHA、创建分支/脚本/映射/变体/README/报告模板/进度文档，按基线修改 workflow（未提交）；原因：用户要求开工。
