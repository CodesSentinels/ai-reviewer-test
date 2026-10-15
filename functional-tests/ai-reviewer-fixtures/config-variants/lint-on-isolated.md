# 配置变体：lint-on-isolated

- 使用它的 FT：FT-191、FT-192、FT-193、FT-194、FT-195、FT-196、FT-197、FT-198、FT-199、FT-200、FT-201、FT-202、FT-203
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant lint-on-isolated` 只打印本文档，不改任何文件。

## 修改内容

覆盖：FT-191 ~ FT-203，以及 FT-211/212/247 的“本地 lint 工具产出”子场景。基线（lint 关闭）下不得判 PASS。

在隔离环境里的 `ai-reviewer.yml` 修改（按用例逐项叠加，不要一次全开）：

```diff
-          enable_lint_tools: false
+          enable_lint_tools: true
+          # 按用例叠加：
+          # enable_eslint / enable_biome / enable_tsc / enable_prettier / enable_semgrep
+          # semgrep_config: p/default
+          # eslint_version / biome_version / tsc_version / prettier_version / semgrep_version
```

## 隔离环境要求（必须全部满足，否则相关 FT 保持 BLOCKED）

- 独立的测试仓库或独立的 GitHub Environment，**不放置**任何业务 Secret：不使用生产 `OPENAI_API_KEY`、`APP_PRIVATE_KEY`、`BOT_PAT`；
- 如需调用模型，使用用户明确提供的**低额度专用 key**，且只配置在该环境；
- GitHub token 使用最小权限（contents: read、pull-requests: write、issues: write），不使用 App 私钥；
- 环境里没有云凭据、SSH 私钥、`~/.aws`、`~/.ssh` 等真实凭据文件（runner 为一次性托管 runner）；
- 在进度文档 Meta 记录 `isolated_env: provided`，并在报告“基线与线上配置差异”写明所用环境。

## 运行前检查清单

- [ ] 确认该环境 Secret 列表中没有生产密钥（只看名称，不读取值）
- [ ] 确认 runner 是一次性的（GitHub-hosted）
- [ ] 确认测试 PR 只在该环境的仓库中创建
- [ ] 脚本侧可选声明：`export AI_REVIEWER_TEST_ISOLATED_ENV=provided`（仅影响 `--case` 的 BLOCKED 提示）

## 观察要点

- “默认关闭”类（FT-196 Prettier、FT-198 Semgrep）：先在**不显式开启**对应工具的 inputs 下运行一次，用日志或 `@ai-reviewer configuration` 输出证明默认关闭；再显式开启运行第二次，对比两次 inputs 与结果；
- FT-193 Biome：`biome.json` 的范围仅限 `utils/**`、`composables/**`，需要在这两个目录下放一个带问题的 `.ts` 文件（由用户手动添加，夹具目录不在范围内）；
- FT-194/195：`workspace/lint/tsc-issue.ts` 故意包含类型错误；有/无 `tsconfig.json` 各跑一次；
- FT-202（安装失败）：把 `*_version` 设为不存在的版本号；FT-203（超时）无法靠 PR 稳定复现，取单测/日志证据。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
