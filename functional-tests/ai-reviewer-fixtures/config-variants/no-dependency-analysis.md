# 配置变体：no-dependency-analysis

- 使用它的 FT：FT-175
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant no-dependency-analysis` 只打印本文档，不改任何文件。

## 修改内容

```diff
-          enable_dependency_analysis: true
+          enable_dependency_analysis: false
```

搭配 FT-170 的跨文件改动：预期不做跨文件分析但审查正常完成，不报错。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
