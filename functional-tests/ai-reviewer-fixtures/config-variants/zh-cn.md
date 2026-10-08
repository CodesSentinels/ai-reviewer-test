# 配置变体：zh-cn

- 使用它的 FT：FT-022
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant zh-cn` 只打印本文档，不改任何文件。

## 修改内容

```diff
+          language: zh-CN
```

预期：摘要与评论使用简体中文。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
