# 配置变体：max-files

- 使用它的 FT：FT-077
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant max-files` 只打印本文档，不改任何文件。

## 修改内容

```diff
+          max_files: "10"
```

搭配 Phase 3 的 `workspace/many/file-001.ts … file-040.ts`：预期最多审查 10 个文件，日志/摘要说明其余被跳过。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
