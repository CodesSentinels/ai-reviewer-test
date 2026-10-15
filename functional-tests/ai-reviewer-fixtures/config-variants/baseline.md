# 配置变体：baseline

- 使用它的 FT：FT-001、FT-002、FT-003、FT-004、FT-006、FT-008、FT-009、FT-010、FT-011、FT-012、FT-013、FT-014、FT-015、FT-016、FT-017、FT-018、FT-019、FT-030、FT-031、FT-032、FT-033、FT-034、FT-035、FT-036、FT-040、FT-050、FT-051、FT-052、FT-053、FT-054、FT-055、FT-056、FT-057、FT-058、FT-059、FT-060、FT-061、FT-062、FT-070、FT-071、FT-072、FT-073、FT-078、FT-079、FT-080、FT-081、FT-082、FT-093、FT-094、FT-095、FT-100、FT-101、FT-102、FT-103、FT-104、FT-105、FT-106、FT-107、FT-108、FT-109、FT-110、FT-111、FT-112、FT-113、FT-114、FT-115、FT-116、FT-118、FT-119、FT-120、FT-121、FT-122、FT-123、FT-124、FT-125、FT-126、FT-127、FT-128、FT-129、FT-130、FT-140、FT-141、FT-142、FT-143、FT-144、FT-145、FT-146、FT-147、FT-148、FT-149、FT-150、FT-151、FT-152、FT-160、FT-161、FT-162、FT-163、FT-164、FT-165、FT-166、FT-167、FT-168、FT-170、FT-171、FT-172、FT-173、FT-174、FT-177、FT-178、FT-179、FT-180、FT-182、FT-183、FT-190、FT-213、FT-220、FT-221、FT-222、FT-223、FT-224、FT-225、FT-226、FT-227、FT-228、FT-229、FT-230、FT-231、FT-232、FT-233、FT-240、FT-241、FT-242、FT-243、FT-244、FT-245、FT-246、FT-248、FT-249、FT-250、FT-251、FT-252、FT-253、FT-260、FT-261、FT-262、FT-263、FT-264、FT-265、FT-266、FT-267、FT-268、FT-269、FT-270、FT-271、FT-272、FT-273、FT-274、FT-275、FT-276、FT-277、FT-278、FT-279、FT-280、FT-281、FT-282、FT-283、FT-290、FT-291、FT-292、FT-293、FT-294、FT-295、FT-296、FT-297、FT-298、FT-299、FT-300
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant baseline` 只打印本文档，不改任何文件。

## 修改内容

基线 = 现有 `.github/workflows/ai-reviewer.yml` + 四处修改（其余保持原样）：

1. ai-reviewer 的 checkout 固定为本轮完整 SHA（`ref: <40 位 SHA>`），不再使用 `Resolve ai-reviewer branch` 的分支表达式；
2. `enable_shell: false`；
3. `enable_lint_tools: false`；
4. `path_filters` 删除 `**/*.md`（用户决定：md 文档不审查。测试用的 `cases/*.md`、README、docs 等不再占用 `max_files` 额度；首轮 run 因 270 个可审查文件 > 150 导致 `workspace/*.ts` 夹具未被审查）。

依据：ai-reviewer 生产 workflow `.github/workflows/openai-review.yml` 与验收文档 `docs/github-only-acceptance-checklist.md` 均采用 shell/lint 关闭；本地 lint 仅适用于无业务密钥的执行面（`src/review.ts`）。

**重要：** GitHub 对 `issue_comment`、`pull_request_review_comment` 事件使用**默认分支（main）上的 workflow**。命令类用例（G/H/I 分区、FT-059/060/061/105/106 等）要先把上述基线 workflow 合入 `main`，否则实际运行的是 main 的旧配置和 ai-reviewer 的 main 分支，证据无效。`pull_request` 事件使用 PR 自己的 workflow，不受影响。

基线中保持不变、但会影响部分用例的现状：`debug: true`、`enable_web_search: true`、`enable_semgrep: true`（总开关关闭，预期不生效）、`debug_resolve_inject_failures: "3"`（锁定 SHA 处注入代码已被注释，不生效）、`setup-node` 的 node 20（只影响 job 的 Node，不影响 action 的 `runs.using: node24`）。
