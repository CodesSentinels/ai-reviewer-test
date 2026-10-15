# 配置变体：missing-config

- 使用它的 FT：FT-005
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant missing-config` 只打印本文档，不改任何文件。

## 修改内容

目的：验证缺少必要配置时明确失败。**不要删除或改动仓库 Secret 本身**，只在 workflow 里把 env 映射改空：

```diff
-          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
+          OPENAI_API_KEY: ""
```

预期：job 以明确的错误信息失败（指出缺少 OPENAI_API_KEY），日志不回显任何 Secret。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
