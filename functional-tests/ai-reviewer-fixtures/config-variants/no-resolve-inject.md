# 配置变体：no-resolve-inject

- 使用它的 FT：（无直接引用，按需使用）
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant no-resolve-inject` 只打印本文档，不改任何文件。

## 修改内容

基线保留 `debug_resolve_inject_failures: "3"`（resolve 时追加 3 个假 thread ID，产生 ok=真实数 failed=3 的受控部分失败）。若它干扰了 FT-113~115 的判定，用本变体重测：

```diff
-          debug_resolve_inject_failures: "3"
+          debug_resolve_inject_failures: "0"
```

预期：resolve 输出不再有 failed=3。FT-061（部分失败可解释）应在基线下判定，不要在本变体下判定。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
