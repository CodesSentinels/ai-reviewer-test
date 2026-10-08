# 配置变体：no-resolve-inject

- 使用它的 FT：（无直接引用，按需使用）
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant no-resolve-inject` 只打印本文档，不改任何文件。

## 修改内容

基线保留 `debug_resolve_inject_failures: "3"`。注意：在锁定 SHA `8c84f45f` 处 `src/commands/handlers/resolve.ts` 里的注入代码已被注释掉，该输入**不生效**，resolve 输出不会出现 failed=3；本变体通常不需要使用，仅在未来 SHA 恢复注入逻辑时才有意义：

```diff
-          debug_resolve_inject_failures: "3"
+          debug_resolve_inject_failures: "0"
```

预期：resolve 输出不再有 failed=3（锁定 SHA 下本来就没有）。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
