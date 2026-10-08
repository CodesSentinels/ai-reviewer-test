# 配置变体：web-search-off

- 使用它的 FT：FT-181
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant web-search-off` 只打印本文档，不改任何文件。

## 修改内容

```diff
-          enable_web_search: true
+          enable_web_search: false
```

预期：日志中没有 `[web_search] executed` 记录。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
