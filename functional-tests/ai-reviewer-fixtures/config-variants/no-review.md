# 配置变体：no-review

- 使用它的 FT：FT-021
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant no-review` 只打印本文档，不改任何文件。

## 修改内容

```diff
+          disable_review: "true"
```

预期：不产生行级评论，仅按配置生成摘要/发布说明（以日志为准）。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
