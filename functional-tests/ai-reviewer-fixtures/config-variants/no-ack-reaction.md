# 配置变体：no-ack-reaction

- 使用它的 FT：FT-117
- 应用方式：手动编辑 `.github/workflows/ai-reviewer.yml` 的 `with:` / `env:`；`--print-variant no-ack-reaction` 只打印本文档，不改任何文件。

## 修改内容

```diff
+          command_ack_reaction: "off"
```

预期：发布命令后评论上不再出现 ack reaction，命令仍然正常执行。

> 取值说明：源码 `options.ts` 里该输入的含义是“命令识别后在用户评论上打的表情（空 / off / none 表示禁用）”，所以关闭要写 `off`（或 `none`），写 `false` 会被当成一个表情名。因为这是评论类事件，必须修改 `main` 上的 workflow，可用 `ack-reaction-batch.sh` 完成。

## 还原

测试结束后把上述改动还原为基线值（建议单独一个“还原”提交），并在进度文档“阶段与运行记录”记录变体 id、应用 commit 与还原 commit。
