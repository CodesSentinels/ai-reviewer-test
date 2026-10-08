# ai-reviewer develop 功能回归夹具

## 测试目的

在 `CodesSentinels/ai-reviewer-test` 中对 `CodesSentinels/ai-reviewer` 的 develop 分支做可重复、可追踪、可按单个功能点（FT）执行的功能回归。本目录提供：

- `case-map.tsv`：FT 映射（事实源，226 个用例），`cases/FT-XXX.md`：每个用例的生成文件、人工步骤、预期、证据；
- `config-variants/`：配置变体说明（沿用同一个 `.github/workflows/ai-reviewer.yml`，不新建 workflow）；
- `workspace/`：脚本生成的故意带缺陷的夹具代码（默认不存在，按需生成）。

## 本轮版本

| 项 | 值 |
|---|---|
| 待测仓库 / 分支 | `CodesSentinels/ai-reviewer` / `develop` |
| 锁定 SHA | `8c84f45fab547821ecefbf56aabbf215eb9d7dbf` |
| SHA 获取时间 | `2026-10-08T06:44:44Z` |
| 测试分支 | `test/ai-reviewer-develop-functional-20261008` |
| 总回归 Issue | https://github.com/CodesSentinels/ai-reviewer-test/issues/299 |

workflow 通过 `actions/checkout` 的 `ref: <完整 SHA>` 固定 ai-reviewer，禁止 develop/main/latest 或分支表达式。

## 基线

现有 `ai-reviewer.yml` + 四处修改：固定 SHA、`enable_shell: false`、`enable_lint_tools: false`、`path_filters` 删除 `**/*.md`（md 不审查）。依赖 shell/lint 开启的用例（FT-184, FT-185, FT-186, FT-187, FT-188, FT-191, FT-192, FT-193, FT-194, FT-195, FT-196, FT-197, FT-198, FT-199, FT-200, FT-201, FT-202, FT-203）需要**无业务密钥的隔离环境**，见 `config-variants/shell-on-isolated.md`、`lint-on-isolated.md`；未提供环境则保持 BLOCKED，基线下不得判 PASS。

覆盖方式统计：e2e 207、unit-evidence 8、needs-injection 11。

## 使用

```bash
bash scripts/generate-ai-reviewer-functional-fixtures.sh --help
bash scripts/generate-ai-reviewer-functional-fixtures.sh --list-cases
bash scripts/generate-ai-reviewer-functional-fixtures.sh --describe FT-001          # 查看用例全部字段与详情
bash scripts/generate-ai-reviewer-functional-fixtures.sh --case FT-001              # 本地只读检查
bash scripts/generate-ai-reviewer-functional-fixtures.sh --case FT-010 --dry-run    # 先 dry-run，列出将创建/跳过/冲突的文件
bash scripts/generate-ai-reviewer-functional-fixtures.sh --list-phase 1
bash scripts/generate-ai-reviewer-functional-fixtures.sh --phase 1 --dry-run
bash scripts/generate-ai-reviewer-functional-fixtures.sh --dry-run --all            # 三个阶段的完整计划（真实生成不支持 --all）
bash scripts/generate-ai-reviewer-functional-fixtures.sh --print-variant max-comments
bash scripts/generate-ai-reviewer-functional-fixtures.sh --check                    # 映射/文档一致性校验
```

脚本只会：读取、检查、打印、写入 `functional-tests/ai-reviewer-fixtures/`。不会 `git add/commit/push`、不会创建 PR、不会发布评论、不会更新 Issue、不会读取 Secret、不会调用 OpenAI。

结果状态（`Result:` 行）：`LOCAL_CHECK_PASS` / `LOCAL_CHECK_FAIL` / `FIXTURE_READY` / `ALREADY_READY` / `MANUAL_ACTION_REQUIRED` / `EXTERNAL_EVIDENCE_REQUIRED` / `BLOCKED` / `CONFLICT`。**这些都不等同于 Issue 中的 PASS**，只有 PR / workflow / 评论里的真实证据才能让 FT 通过。

### 依赖

`--case` 遇到缺失的前置用例返回 `BLOCKED` 并给出推荐命令；只有显式加 `--with-dependencies` 才会先准备依赖。例如 FT-030 依赖 FT-010（baseline 夹具）：

```bash
bash scripts/generate-ai-reviewer-functional-fixtures.sh --case FT-010
bash scripts/generate-ai-reviewer-functional-fixtures.sh --case FT-030
```

## scenario 与阶段

scenario：baseline、logic-bug、security-bug、performance-bug、cross-file、lint、path-filter、noise-limit、prompt-injection、large-diff（外加 style-nit、file-ops、incremental、revert 等辅助场景，见 `--list-cases`）。

| 阶段 | 内容 |
|---|---|
| Phase 1 | baseline、初始逻辑缺陷、安全缺陷、性能缺陷、初始跨文件接口、基础 lint 问题、lint 报告夹具、增量/回退/文件操作的初始版本 |
| Phase 2 | 新逻辑缺陷（同时修复一个旧缺陷）、修改跨文件接口并保留旧调用方、新安全问题、增量审查的第二个 commit、删除/重命名/新增文件 |
| Phase 3 | 回退一个修改、被过滤文件（dist/generated/二进制/lock/txt）、超评论上限问题、提示词注入数据、适度 large diff、多文件 |

marker：`.phase-1-generated`、`.phase-2-generated`、`.phase-3-generated`。不得跳过前置阶段；每个阶段生成后请检查 diff、手动提交并推送，再进入下一阶段（增量审查依赖逐步 commit）。

## 故意缺陷清单（不要把这些写进夹具注释，以免给审查模型泄题）

| 文件 | 阶段 | 故意缺陷 | 关联 FT |
|---|---|---|---|
| `workspace/orders/pricing.ts` | P1 | 循环边界 `items.length - 1` 漏掉最后一项；折扣被加到总价而不是扣减 | FT-030/033/034/035 |
| `workspace/orders/pricing.ts` | P2 | 修复循环边界；保留折扣符号问题；新增税费 `Math.floor` 丢精度 | FT-030、FT-051 |
| `workspace/auth/session.ts` | P1 | 硬编码假 token；SQL 字符串拼接；`==` 比较令牌；HTML 拼接（XSS） | FT-031 |
| `workspace/auth/token-check.ts` | P2 | 非常量时间比较；`eval` 用户表达式 | FT-031 |
| `workspace/reports/aggregate.ts` | P1 | `includes` 去重 O(n²)；循环内 filter；循环里反复复制并排序 | FT-032 |
| `workspace/style/nits.ts` | P1 | 命名/空格/引号/分号等轻微样式问题（刻意违反 Prettier，**不要格式化**） | FT-036/037 |
| `workspace/shared/*`、`workspace/orders/*` | P1/P2 | 跨文件：`formatOrder` 在 P2 改签名并改返回语义，旧调用方（summary/alias-user/index-user/OrderCard.vue）保持不变 | FT-170~174、FT-179 |
| `workspace/lint/lint-issues.ts` | P1 | 未使用变量、`console.log`、`==`、`map` 回调缺少返回值 | FT-191 |
| `workspace/lint/tsc-issue.ts` | P1 | 故意的类型错误（该文件不可编译，仅作夹具） | FT-194 |
| `workspace/lint-report/*.json` | P1 | 外部 lint 报告：valid、顶层畸形、绝对路径、`..`、非法 severity、非法行列、超量（600 条）、提示词注入、与 AI finding 同行 | FT-204~212、FT-247 |
| `workspace/orders/inventory.ts` | P1/P2 | `reserve` 不检查库存不足；P2 新增 `release` 不校验数量 | FT-051/052 |
| `workspace/fileops/*` | P1/P2 | P2 删除 legacy.ts、重命名 old-name.ts→renamed.ts、新增 new-file.ts | FT-079~081 |
| `workspace/revert/rules.ts` | P1/P2/P3 | P2 把 `>= 18` 改成 `> 18`，P3 回退到 P1 内容 | FT-058 |
| `workspace/filtered/*`、`dist/`、`generated/`、`assets/` | P3 | 被过滤的文件（txt、lock、dist、generated、png） | FT-072~076 |
| `workspace/noise/many-issues.ts` | P3 | 30 个函数，各含除零/`eval`/`==` 之一，超过评论上限 | FT-090~094 |
| `workspace/large/large-module.ts` | P3 | 120 个函数的大文件，每 40 个有一处除零 | FT-078、FT-292 |
| `workspace/many/file-001.ts…040.ts` | P3 | 40 个小文件，用于 `max_files` | FT-077 |
| `workspace/unresolved/importer.ts` | P3 | 无法解析的相对/别名导入 | FT-177 |
| `workspace/injection/*` | P3 | 注释里的提示词注入、含空格与分号的文件名、PR 标题/描述载荷（`payloads.txt`）、shell 诱导（仅隔离环境用） | FT-187/188、FT-243~246 |

所有假 Secret 统一为 `FAKE_TEST_TOKEN_DO_NOT_USE`，不包含真实凭据。

## diff 检查与手动提交

```bash
bash scripts/generate-ai-reviewer-functional-fixtures.sh --phase 1 --dry-run
bash scripts/generate-ai-reviewer-functional-fixtures.sh --phase 1
git status --short
git diff -- functional-tests/ai-reviewer-fixtures
```

确认只包含预期的夹具后手动 `git add` / `git commit` / `git push` 并创建（或更新）测试 PR。**不要对 `workspace/` 运行 prettier/eslint --fix**：夹具故意带缺陷和不规范样式，被格式化后脚本会把它视为“已被手改”而报 CONFLICT（`--force` 可以覆盖受管夹具文件）。

## 幂等与覆盖规则

- 重复执行不会重复追加；内容相同报 unchanged；
- 内容不同且不是脚本上次写入的原样 → 默认拒绝覆盖（CONFLICT）；
- `--force` 只覆盖受管夹具文件，且仅限本目录；
- 受管文件登记在 `.managed-files`（路径 + sha256），`.cases-prepared` 记录已准备的用例，二者都是脚本维护的文件，不要手改。

## 增量 commit

1. `--phase 1` → 提交 → 创建 PR → 等审查完成；
2. `--phase 2` → 检查增量 diff → 提交 → 推送 → 等增量审查完成；
3. `--phase 3` → 提交 → 推送 → 等审查完成。
配置变体在同一 PR 的后续 commit（或独立短 PR）中按 `--print-variant <id>` 手动应用，并在测试后还原。

## 安全清理

先看会动哪些文件，再决定是否删除，不要用通配符批量删除：

```bash
git status --short -- functional-tests/ai-reviewer-fixtures
git clean -n -- functional-tests/ai-reviewer-fixtures/workspace    # 只预览，不删除
```

确认后可手动删除 `functional-tests/ai-reviewer-fixtures/workspace/` 与 `.phase-*-generated`、`.managed-files`、`.cases-prepared`（已提交的内容请用 `git revert`/新分支处理，不要 reset --hard）。

## FT 与命令映射

| FT | 标题 | 类型 | 阶段 | 覆盖 | 命令 |
|---|---|---|---|---|---|
| FT-001 | 确认测试仓库正确 | local-validation | preparation | e2e | `--case FT-001` |
| FT-002 | 成功解析 develop 完整 SHA | local-validation | preparation | e2e | `--case FT-002` |
| FT-003 | Action 固定引用完整 SHA | local-validation | preparation | e2e | `--case FT-003` |
| FT-004 | Node 24 下成功加载 | external-observation | Phase 1 | unit-evidence | `--case FT-004` |
| FT-005 | 缺少必要配置时明确失败 | external-observation | variant | e2e | `--case FT-005` |
| FT-006 | 未知或无关事件安全跳过 | external-observation | command | e2e | `--case FT-006` |
| FT-007 | debug=false 不输出敏感内容 | external-observation | variant | e2e | `--case FT-007` |
| FT-008 | debug=true 仍不泄漏 Token | external-observation | Phase 1 | e2e | `--case FT-008` |
| FT-009 | workflow 使用最小权限 | local-validation | preparation | e2e | `--case FT-009` |
| FT-010 | 打开 PR 自动触发审查 | external-observation | Phase 1 | e2e | `--case FT-010` |
| FT-011 | synchronize/push 触发审查 | external-observation | Phase 2 | e2e | `--case FT-011` |
| FT-012 | reopened 触发审查 | external-observation | command | e2e | `--case FT-012` |
| FT-013 | 生成唯一顶部摘要 | external-observation | Phase 1 | e2e | `--case FT-013` |
| FT-014 | 后续审查更新既有摘要 | external-observation | Phase 2 | e2e | `--case FT-014` |
| FT-015 | 摘要包含 Walkthrough | external-observation | Phase 1 | e2e | `--case FT-015` |
| FT-016 | 摘要包含 Changes 表格 | external-observation | Phase 1 | e2e | `--case FT-016` |
| FT-017 | 相似文件合理合并 | external-observation | Phase 1 | e2e | `--case FT-017` |
| FT-018 | 正确生成发布说明 | external-observation | Phase 1 | e2e | `--case FT-018` |
| FT-019 | 发布说明写入预期位置 | external-observation | Phase 1 | e2e | `--case FT-019` |
| FT-020 | disable_release_notes 生效 | external-observation | variant | e2e | `--case FT-020` |
| FT-021 | disable_review 生效 | external-observation | variant | e2e | `--case FT-021` |
| FT-022 | language=zh-CN 生效 | external-observation | variant | e2e | `--case FT-022` |
| FT-023 | bot_icon 生效 | external-observation | variant | e2e | `--case FT-023` |
| FT-024 | bot_name 生效 | external-observation | variant | e2e | `--case FT-024` |
| FT-030 | 识别明确逻辑错误 | fixture | Phase 1 | e2e | `--case FT-030` |
| FT-031 | 识别明确安全问题 | fixture | Phase 1 | e2e | `--case FT-031` |
| FT-032 | 识别明显性能问题 | fixture | Phase 1 | e2e | `--case FT-032` |
| FT-033 | 评论位于实际变更行 | fixture | Phase 1 | e2e | `--case FT-033` |
| FT-034 | 不评论不存在或未变更行 | fixture | Phase 1 | e2e | `--case FT-034` |
| FT-035 | 建议代码格式正确 | fixture | Phase 1 | e2e | `--case FT-035` |
| FT-036 | 默认忽略轻微样式问题 | fixture | Phase 1 | e2e | `--case FT-036` |
| FT-037 | review_simple_changes=true 生效 | fixture | Phase 1 | e2e | `--case FT-037` |
| FT-038 | review_comment_lgtm=false 生效 | external-observation | variant | e2e | `--case FT-038` |
| FT-039 | review_comment_lgtm=true 生效 | external-observation | variant | e2e | `--case FT-039` |
| FT-040 | 非法模型输出安全处理 | external-observation | Phase 1 | needs-injection | `--case FT-040` |
| FT-050 | 首次审查覆盖 base 到 HEAD | external-observation | Phase 1 | e2e | `--case FT-050` |
| FT-051 | 第二个 commit 仅审查新增变化 | multi-phase | Phase 1,2 | e2e | `--case FT-051` |
| FT-052 | 已审查 commit 状态正确保存 | multi-phase | Phase 1,2 | e2e | `--case FT-052` |
| FT-053 | 重跑相同 workflow 不重复发布 | external-observation | Phase 2 | e2e | `--case FT-053` |
| FT-054 | 重复事件不重复执行完整审查 | external-observation | Phase 2 | e2e | `--case FT-054` |
| FT-055 | 相同 finding 不重复发布 | external-observation | Phase 2 | e2e | `--case FT-055` |
| FT-056 | 旧 HEAD 不覆盖新结果 | multi-phase | Phase 1,2 | e2e | `--case FT-056` |
| FT-057 | 陈旧事件安全跳过 | multi-phase | Phase 1,2 | e2e | `--case FT-057` |
| FT-058 | 修改回退后状态一致 | multi-phase | Phase 2,3 | e2e | `--case FT-058` |
| FT-059 | full review 执行全量审查 | manual-command | command | e2e | `--case FT-059` |
| FT-060 | summary 只重建摘要 | manual-command | command | e2e | `--case FT-060` |
| FT-061 | 部分评论失败时状态可解释 | manual-command | command | e2e | `--case FT-061` |
| FT-062 | 异常以失败状态退出 | external-observation | Phase 1 | unit-evidence | `--case FT-062` |
| FT-070 | `@ai-reviewer: ignore` 跳过审查 | external-observation | command | e2e | `--case FT-070` |
| FT-071 | 移除 ignore 后恢复审查 | external-observation | command | e2e | `--case FT-071` |
| FT-072 | path_filters 包含规则生效 | fixture | Phase 3 | e2e | `--case FT-072` |
| FT-073 | path_filters 排除规则生效 | fixture | Phase 3 | e2e | `--case FT-073` |
| FT-074 | dist 默认排除 | fixture | Phase 3 | e2e | `--case FT-074` |
| FT-075 | generated 默认排除 | fixture | Phase 3 | e2e | `--case FT-075` |
| FT-076 | 二进制和图片默认排除 | fixture | Phase 3 | e2e | `--case FT-076` |
| FT-077 | max_files 生效 | fixture | Phase 3 | e2e | `--case FT-077` |
| FT-078 | 超大 diff 安全处理 | fixture | Phase 3 | e2e | `--case FT-078` |
| FT-079 | 新增文件处理正确 | multi-phase | Phase 1,2 | e2e | `--case FT-079` |
| FT-080 | 删除文件处理正确 | multi-phase | Phase 1,2 | e2e | `--case FT-080` |
| FT-081 | 重命名文件处理正确 | multi-phase | Phase 1,2 | e2e | `--case FT-081` |
| FT-082 | 空 diff 不产生垃圾评论 | external-observation | command | e2e | `--case FT-082` |
| FT-090 | max_review_comments 生效 | fixture | Phase 3 | e2e | `--case FT-090` |
| FT-091 | 超限时优先保留高严重度问题 | fixture | Phase 3 | e2e | `--case FT-091` |
| FT-092 | 截断后不重复评论 | fixture | Phase 3 | e2e | `--case FT-092` |
| FT-093 | 相似 finding 正确去重 | fixture | Phase 3 | e2e | `--case FT-093` |
| FT-094 | 摘要与评论数量合理 | fixture | Phase 3 | e2e | `--case FT-094` |
| FT-095 | 简单改动不产生大量噪音 | fixture | Phase 3 | e2e | `--case FT-095` |
| FT-100 | `@ai-reviewer help` | manual-command | command | e2e | `--case FT-100` |
| FT-101 | `@codesentinel help` | manual-command | command | e2e | `--case FT-101` |
| FT-102 | 真实 bot login 可触发命令 | manual-command | command | e2e | `--case FT-102` |
| FT-103 | configuration | manual-command | command | e2e | `--case FT-103` |
| FT-104 | review | manual-command | command | e2e | `--case FT-104` |
| FT-105 | full review | manual-command | command | e2e | `--case FT-105` |
| FT-106 | summary | manual-command | command | e2e | `--case FT-106` |
| FT-107 | pause | manual-command | command | e2e | `--case FT-107` |
| FT-108 | pause 后不自动审查 | external-observation | command | e2e | `--case FT-108` |
| FT-109 | resume | manual-command | command | e2e | `--case FT-109` |
| FT-110 | resume 后恢复审查 | external-observation | command | e2e | `--case FT-110` |
| FT-111 | 重复 pause 幂等 | manual-command | command | e2e | `--case FT-111` |
| FT-112 | 重复 resume 幂等 | manual-command | command | e2e | `--case FT-112` |
| FT-113 | resolve | manual-command | command | e2e | `--case FT-113` |
| FT-114 | resolve 只解决 bot thread | manual-command | command | e2e | `--case FT-114` |
| FT-115 | resolve 不解决真人 thread | manual-command | command | e2e | `--case FT-115` |
| FT-116 | 命令 ack reaction 生效 | external-observation | command | e2e | `--case FT-116` |
| FT-117 | reaction 关闭配置生效 | external-observation | variant | e2e | `--case FT-117` |
| FT-118 | 相同评论只执行一次 | manual-command | command | e2e | `--case FT-118` |
| FT-119 | 未知英文命令返回帮助 | manual-command | command | e2e | `--case FT-119` |
| FT-120 | 自然语言进入对话 | manual-command | command | e2e | `--case FT-120` |
| FT-121 | 命令大小写不敏感 | manual-command | command | e2e | `--case FT-121` |
| FT-122 | 邮箱内 mention 不误触发 | manual-command | command | e2e | `--case FT-122` |
| FT-123 | 相似用户名不误触发 | manual-command | command | e2e | `--case FT-123` |
| FT-124 | 过长命令被拒绝 | manual-command | command | e2e | `--case FT-124` |
| FT-125 | 参数数量超限被拒绝 | manual-command | command | e2e | `--case FT-125` |
| FT-126 | 单参数过长被拒绝 | manual-command | command | e2e | `--case FT-126` |
| FT-127 | Shell 元字符被拒绝 | manual-command | command | e2e | `--case FT-127` |
| FT-128 | 速率限制生效 | manual-command | command | e2e | `--case FT-128` |
| FT-129 | 顶层评论支持命令 | manual-command | command | e2e | `--case FT-129` |
| FT-130 | 行级 thread 支持命令 | manual-command | command | e2e | `--case FT-130` |
| FT-140 | PR 作者可执行 review | manual-command | command | e2e | `--case FT-140` |
| FT-141 | PR 作者可执行 full review | manual-command | command | e2e | `--case FT-141` |
| FT-142 | PR 作者可执行 summary | manual-command | command | e2e | `--case FT-142` |
| FT-143 | 作者豁免不适用于 pause | manual-command | command | e2e | `--case FT-143` |
| FT-144 | 作者豁免不适用于 resume | manual-command | command | e2e | `--case FT-144` |
| FT-145 | 作者豁免不适用于 resolve | manual-command | command | e2e | `--case FT-145` |
| FT-146 | write 用户可执行受限命令 | manual-command | command | e2e | `--case FT-146` |
| FT-147 | triage 用户可执行 configuration | manual-command | command | e2e | `--case FT-147` |
| FT-148 | read 用户可执行 help | manual-command | command | e2e | `--case FT-148` |
| FT-149 | 无权限用户被拒绝 | manual-command | command | e2e | `--case FT-149` |
| FT-150 | 权限查询失败时 fail closed | external-observation | command | unit-evidence | `--case FT-150` |
| FT-151 | GitHub 权限术语正确 | external-observation | command | e2e | `--case FT-151` |
| FT-152 | GitLab权限术语正确 | external-gitlab | gitlab | e2e | `--case FT-152` |
| FT-160 | 回复 bot 行级评论时结合 diff 回答 | manual-command | command | e2e | `--case FT-160` |
| FT-161 | 非 bot thread 显式 mention 可回答 | manual-command | command | e2e | `--case FT-161` |
| FT-162 | 无 mention 时不误回复 | manual-command | command | e2e | `--case FT-162` |
| FT-163 | bot 自评论不触发回复 | manual-command | command | e2e | `--case FT-163` |
| FT-164 | 多轮对话保留上下文 | manual-command | command | e2e | `--case FT-164` |
| FT-165 | 长评论链安全截断 | manual-command | command | e2e | `--case FT-165` |
| FT-166 | 顶层自然语言提问行为正确 | manual-command | command | e2e | `--case FT-166` |
| FT-167 | 不声称读取不可用内容 | manual-command | command | e2e | `--case FT-167` |
| FT-168 | 重复 webhook 不重复回答 | manual-command | command | e2e | `--case FT-168` |
| FT-170 | 识别导出函数签名变化 | multi-phase | Phase 1,2 | e2e | `--case FT-170` |
| FT-171 | 识别返回语义变化 | multi-phase | Phase 1,2 | e2e | `--case FT-171` |
| FT-172 | 支持相对路径导入 | fixture | Phase 1 | e2e | `--case FT-172` |
| FT-173 | 支持别名导入 | fixture | Phase 1 | e2e | `--case FT-173` |
| FT-174 | 支持目录 index 导入 | fixture | Phase 1 | e2e | `--case FT-174` |
| FT-175 | 关闭依赖分析后安全降级 | external-observation | variant | e2e | `--case FT-175` |
| FT-176 | max_dependency_files 生效 | external-observation | variant | e2e | `--case FT-176` |
| FT-177 | 无法解析依赖时安全降级 | fixture | Phase 3 | e2e | `--case FT-177` |
| FT-178 | 仓库树缓存不跨 PR 污染 | external-observation | command | e2e | `--case FT-178` |
| FT-179 | 当前技术栈依赖分析正确 | fixture | Phase 1 | e2e | `--case FT-179` |
| FT-180 | enable_web_search=true 生效 | external-observation | Phase 1 | e2e | `--case FT-180` |
| FT-181 | enable_web_search=false 生效 | external-observation | variant | e2e | `--case FT-181` |
| FT-182 | 搜索失败后安全降级 | external-observation | Phase 1 | needs-injection | `--case FT-182` |
| FT-183 | enable_shell=false 时不执行 shell | external-observation | Phase 1 | e2e | `--case FT-183` |
| FT-184 | shell=true 只在隔离无密钥环境测试 | manual-security | security | e2e | `--case FT-184` |
| FT-185 | shell 具有超时和输出限制 | external-observation | variant | e2e | `--case FT-185` |
| FT-186 | shell 输出脱敏 | external-observation | variant | e2e | `--case FT-186` |
| FT-187 | PR 内容不能诱导读取环境变量 | fixture | Phase 3 | e2e | `--case FT-187` |
| FT-188 | PR 内容不能诱导读取凭据目录 | fixture | Phase 3 | e2e | `--case FT-188` |
| FT-190 | enable_lint_tools=false 生效 | external-observation | Phase 1 | e2e | `--case FT-190` |
| FT-191 | ESLint 有配置时发现问题 | fixture | Phase 1 | e2e | `--case FT-191` |
| FT-192 | ESLint 无配置时安全降级 | fixture | Phase 1 | e2e | `--case FT-192` |
| FT-193 | Biome 返回结构化结果 | fixture | Phase 1 | e2e | `--case FT-193` |
| FT-194 | tsc 有 tsconfig 时运行 | fixture | Phase 1 | e2e | `--case FT-194` |
| FT-195 | tsc 无配置时安全降级 | fixture | Phase 1 | e2e | `--case FT-195` |
| FT-196 | Prettier 默认关闭 | external-observation | variant | e2e | `--case FT-196` |
| FT-197 | 显式开启 Prettier 后生效 | external-observation | variant | e2e | `--case FT-197` |
| FT-198 | Semgrep 默认关闭 | external-observation | variant | e2e | `--case FT-198` |
| FT-199 | 显式开启 Semgrep 后生效 | external-observation | variant | e2e | `--case FT-199` |
| FT-200 | semgrep_config 生效 | external-observation | variant | e2e | `--case FT-200` |
| FT-201 | 工具版本覆盖生效 | external-observation | variant | e2e | `--case FT-201` |
| FT-202 | 工具安装失败安全降级 | external-observation | variant | e2e | `--case FT-202` |
| FT-203 | 工具超时安全处理 | external-observation | variant | unit-evidence | `--case FT-203` |
| FT-204 | 外部 lint_report_path 可读取 | fixture | Phase 1 | e2e | `--case FT-204` |
| FT-205 | 畸形报告顶层被拒绝 | fixture | Phase 1 | e2e | `--case FT-205` |
| FT-206 | 绝对路径 finding 被丢弃 | fixture | Phase 1 | e2e | `--case FT-206` |
| FT-207 | `..` 路径被丢弃 | fixture | Phase 1 | e2e | `--case FT-207` |
| FT-208 | 非法 severity 被丢弃 | fixture | Phase 1 | e2e | `--case FT-208` |
| FT-209 | 非法行列号被丢弃 | fixture | Phase 1 | e2e | `--case FT-209` |
| FT-210 | 超量 finding 被截断 | fixture | Phase 1 | e2e | `--case FT-210` |
| FT-211 | lint 提示词注入无效 | fixture | Phase 1 | e2e | `--case FT-211` |
| FT-212 | lint 与 AI finding 去重 | fixture | Phase 1 | e2e | `--case FT-212` |
| FT-213 | 持密钥 job 不执行 PR 代码 | manual-security | security | e2e | `--case FT-213` |
| FT-220 | OpenAI 429 重试 | external-observation | Phase 1 | needs-injection | `--case FT-220` |
| FT-221 | OpenAI 5xx 重试 | external-observation | Phase 1 | needs-injection | `--case FT-221` |
| FT-222 | OpenAI 超时正确处理 | external-observation | Phase 1 | needs-injection | `--case FT-222` |
| FT-223 | 空响应安全处理 | external-observation | Phase 1 | needs-injection | `--case FT-223` |
| FT-224 | 非法 JSON 安全处理 | external-observation | Phase 1 | needs-injection | `--case FT-224` |
| FT-225 | Markdown 包裹输出正确处理 | external-observation | Phase 1 | needs-injection | `--case FT-225` |
| FT-226 | GitHub API 暂时失败时重试 | external-observation | Phase 1 | needs-injection | `--case FT-226` |
| FT-227 | GitLab API 暂时失败时重试 | external-gitlab | gitlab | needs-injection | `--case FT-227` |
| FT-228 | 部分评论失败不破坏全部结果 | external-observation | Phase 1 | needs-injection | `--case FT-228` |
| FT-229 | uncaughtException 导致任务失败 | external-observation | Phase 1 | unit-evidence | `--case FT-229` |
| FT-230 | unhandledRejection 导致任务失败 | external-observation | Phase 1 | unit-evidence | `--case FT-230` |
| FT-231 | 日志不包含 Authorization header | external-observation | command | e2e | `--case FT-231` |
| FT-232 | 日志不包含 Token 或 API Key | external-observation | command | e2e | `--case FT-232` |
| FT-233 | 日志不包含敏感 URL 参数 | external-observation | command | e2e | `--case FT-233` |
| FT-240 | fork PR 不在持密钥 job 执行代码 | manual-security | security | e2e | `--case FT-240` |
| FT-241 | fork 无法通过 workflow 修改获取 Secret | manual-security | security | e2e | `--case FT-241` |
| FT-242 | fork artifact 被视为不可信数据 | manual-security | security | e2e | `--case FT-242` |
| FT-243 | 恶意 PR 标题不能覆盖系统提示 | manual-security | security | e2e | `--case FT-243` |
| FT-244 | 恶意 PR 描述不能覆盖系统提示 | manual-security | security | e2e | `--case FT-244` |
| FT-245 | 恶意代码注释不能覆盖系统提示 | fixture | Phase 3 | e2e | `--case FT-245` |
| FT-246 | 恶意文件名不能突破路径边界 | fixture | Phase 3 | e2e | `--case FT-246` |
| FT-247 | 恶意 lint message 不能泄密 | fixture | Phase 1 | e2e | `--case FT-247` |
| FT-248 | bot 自评论不形成循环 | external-observation | command | e2e | `--case FT-248` |
| FT-249 | 重复 webhook 不形成循环 | external-observation | command | e2e | `--case FT-249` |
| FT-250 | 日志无 OPENAI_API_KEY | external-observation | command | e2e | `--case FT-250` |
| FT-251 | 日志无 GITHUB_TOKEN | external-observation | command | e2e | `--case FT-251` |
| FT-252 | 日志无 GITLAB_PAT | external-gitlab | gitlab | e2e | `--case FT-252` |
| FT-253 | 双平台状态 marker 独立 | external-gitlab | gitlab | e2e | `--case FT-253` |
| FT-260 | MR open 触发审查 | external-gitlab | gitlab | e2e | `--case FT-260` |
| FT-261 | MR push 触发增量审查 | external-gitlab | gitlab | e2e | `--case FT-261` |
| FT-262 | MR reopen 触发审查 | external-gitlab | gitlab | e2e | `--case FT-262` |
| FT-263 | merge/close 不误触发 | external-gitlab | gitlab | e2e | `--case FT-263` |
| FT-264 | 顶层 Note 进入命令路径 | external-gitlab | gitlab | e2e | `--case FT-264` |
| FT-265 | diff discussion 进入行级路径 | external-gitlab | gitlab | e2e | `--case FT-265` |
| FT-266 | 非 MR note 被忽略 | external-gitlab | gitlab | e2e | `--case FT-266` |
| FT-267 | system note 被忽略 | external-gitlab | gitlab | e2e | `--case FT-267` |
| FT-268 | 非 create note 被忽略 | external-gitlab | gitlab | e2e | `--case FT-268` |
| FT-269 | 缺 project.id 时 fail closed | external-gitlab | gitlab | e2e | `--case FT-269` |
| FT-270 | 缺 MR iid 时 fail closed | external-gitlab | gitlab | e2e | `--case FT-270` |
| FT-271 | 缺 last_commit.id 时 fail closed | external-gitlab | gitlab | e2e | `--case FT-271` |
| FT-272 | 未知 object_kind 安全跳过 | external-gitlab | gitlab | e2e | `--case FT-272` |
| FT-273 | fork MR fail closed | external-gitlab | gitlab | e2e | `--case FT-273` |
| FT-274 | 陈旧 MR HEAD 被跳过 | external-gitlab | gitlab | e2e | `--case FT-274` |
| FT-275 | 相同 headSha 只审查一次 | external-gitlab | gitlab | e2e | `--case FT-275` |
| FT-276 | 相同 note ID 只执行一次 | external-gitlab | gitlab | e2e | `--case FT-276` |
| FT-277 | bot 身份不一致时告警 | external-gitlab | gitlab | e2e | `--case FT-277` |
| FT-278 | subgroup 路径解析正确 | external-gitlab | gitlab | e2e | `--case FT-278` |
| FT-279 | PAT 身份与权限正确 | external-gitlab | gitlab | e2e | `--case FT-279` |
| FT-280 | CI_JOB_TOKEN 限制有明确诊断 | external-gitlab | gitlab | e2e | `--case FT-280` |
| FT-281 | GitLab API host 校验正确 | external-gitlab | gitlab | e2e | `--case FT-281` |
| FT-282 | GitLab diff 定位正确 | external-gitlab | gitlab | e2e | `--case FT-282` |
| FT-283 | GitLab 帮助术语正确 | external-gitlab | gitlab | e2e | `--case FT-283` |
| FT-290 | 记录小 PR 执行时间 | external-observation | Phase 1 | e2e | `--case FT-290` |
| FT-291 | 记录中等 PR 执行时间 | external-observation | Phase 2 | e2e | `--case FT-291` |
| FT-292 | 记录大 PR 执行时间 | fixture | Phase 3 | e2e | `--case FT-292` |
| FT-293 | 记录 light model 调用数量 | external-observation | Phase 2 | e2e | `--case FT-293` |
| FT-294 | 记录 heavy model 调用数量 | external-observation | Phase 2 | e2e | `--case FT-294` |
| FT-295 | 记录平台 API 调用情况 | external-observation | Phase 2 | e2e | `--case FT-295` |
| FT-296 | OpenAI 并发限制生效 | external-observation | Phase 1 | unit-evidence | `--case FT-296` |
| FT-297 | GitHub API 并发限制生效 | external-observation | Phase 1 | unit-evidence | `--case FT-297` |
| FT-298 | 重复事件不重复产生模型费用 | external-observation | Phase 2 | e2e | `--case FT-298` |
| FT-299 | 日志可区分各执行阶段 | external-observation | Phase 1 | e2e | `--case FT-299` |
| FT-300 | 最终报告包含发布建议 | local-validation | preparation | e2e | `--case FT-300` |

