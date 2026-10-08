# 配置变体：max-comments

- 使用它的 FT：FT-090、FT-091、FT-092
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant max-comments` 只打印本文档，不改任何文件。

## 修改内容

```diff
+          max_review_comments: "5"
```

搭配 Phase 3 的 `workspace/noise/many-issues.ts`（30 处问题）：预期行级评论数 ≤ 5，优先保留高严重度（eval 注入类），截断后摘要说明被省略数量，且重跑不重复评论。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
