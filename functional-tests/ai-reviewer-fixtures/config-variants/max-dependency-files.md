# 配置变体：max-dependency-files

- 使用它的 FT：FT-176
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant max-dependency-files` 只打印本文档，不改任何文件。

## 修改内容

```diff
+          max_dependency_files: "1"
```

预期：依赖分析最多读取 1 个关联文件，日志可见限制生效。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
