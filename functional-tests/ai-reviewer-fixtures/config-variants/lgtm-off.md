# 配置变体：lgtm-off

- 使用它的 FT：FT-038
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant lgtm-off` 只打印本文档，不改任何文件。

## 修改内容

基线已是 `review_comment_lgtm: false`，无需改动；只需在“干净代码”场景（如 `workspace/baseline/greeter.ts` 的无缺陷改动）下确认 LGTM 不发行级评论。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
