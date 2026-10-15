# 配置变体：no-release-notes

- 使用它的 FT：FT-020
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant no-release-notes` 只打印本文档，不改任何文件。

## 修改内容

```diff
+          disable_release_notes: "true"
```

预期：PR 描述不被写入发布说明区块，摘要照常生成。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
