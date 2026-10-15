# 配置变体：no-path-filters

- 使用它的 FT：FT-074、FT-075、FT-076
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant no-path-filters` 只打印本文档，不改任何文件。

## 修改内容

删除整个 `path_filters:` 输入（让 action 使用默认过滤），验证 dist/generated/二进制默认被排除：

```diff
-          path_filters: |
-            **/*.ts
-            ...
```

搭配 Phase 3 的 `workspace/dist/output.js`、`workspace/generated/api.generated.ts`、`workspace/assets/pixel.png`：预期这三个文件不被审查（摘要/日志可见被跳过）。
注意：删除后 `.md/.yml` 等也会被审查，范围变大，用完立即还原。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
