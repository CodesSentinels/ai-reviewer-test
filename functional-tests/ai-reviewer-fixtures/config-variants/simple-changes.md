# 配置变体：simple-changes

- 使用它的 FT：FT-037
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant simple-changes` 只打印本文档，不改任何文件。

## 修改内容

```diff
-          review_simple_changes: false
+          review_simple_changes: true
```

搭配 FT-036 的 `workspace/style/nits.ts`：预期琐碎改动也会被审查（对比基线下被忽略）。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
