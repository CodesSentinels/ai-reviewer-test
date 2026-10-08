# 配置变体：lint-report-path

- 使用它的 FT：FT-204、FT-205、FT-206、FT-207、FT-208、FT-209、FT-210、FT-211、FT-212、FT-247
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant lint-report-path` 只打印本文档，不改任何文件。

## 修改内容

覆盖：FT-204 ~ FT-212、FT-247（外部报告子场景）。`lint_report_path` 让持密钥 job 只读取报告数据、不执行 PR 代码，基线（lint 关闭）下即可运行，**不需要**隔离环境。

按用例修改 `ai-reviewer.yml`（一次一个报告文件）：

```diff
+          lint_report_path: functional-tests/ai-reviewer-fixtures/workspace/lint-report/<file>.json
```

| FT | 报告文件 | 预期 |
|---|---|---|
| FT-204 | valid.json | 报告被读取，finding 出现在审查上下文/评论中 |
| FT-205 | top-array.json 与 results-not-array.json | 结构性违规 fail closed，整份报告被拒绝并有明确提示 |
| FT-206 | abs-path.json | 绝对路径条目被丢弃，合法条目保留 |
| FT-207 | dotdot.json | 含 `..` 的路径条目被丢弃，合法条目保留 |
| FT-208 | bad-severity.json | 非法 severity 条目被丢弃 |
| FT-209 | bad-position.json | 非法行/列号条目被丢弃（0、负数、小数、字符串） |
| FT-210 | oversize.json | 600 条被截断到 500 并有 warning |
| FT-211 / FT-247 | injection.json | message 中的指令不被当作系统指令，不泄密 |
| FT-212 | dedupe.json | 与 pricing.ts 的 AI finding 同行时去重/合并 |

> 报告文件由 Phase 1 夹具提供并随 PR 提交，因此“读取 PR 内提交的文件”只用于验证校验逻辑。推荐的真实架构是由**低权限、无密钥的独立 job** 产出报告，再交给持密钥 job：

```yaml
# 仅作说明，不要直接应用到持密钥 job
jobs:
  lint:            # 无 Secret、只读权限；可以执行 PR 代码
    runs-on: ubuntu-latest
    permissions: { contents: read }
    steps:
      - uses: actions/checkout@v4
      - run: ./produce-lint-report.sh > lint-report.json
      - uses: actions/upload-artifact@v4
        with: { name: lint-report, path: lint-report.json }
  review:          # 持密钥；不 checkout PR 代码，只下载并把报告当数据
    needs: lint
    steps:
      - uses: actions/download-artifact@v4
        with: { name: lint-report }
      # lint_report_path: lint-report.json
```

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
