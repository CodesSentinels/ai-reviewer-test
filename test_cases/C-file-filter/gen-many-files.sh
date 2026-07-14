#!/usr/bin/env bash
# 域 C（C3 max_files）：生成 6 个 TS 文件，配合 workflow 中 max_files: 3 验证跳过统计。
set -euo pipefail
OUT="${1:-test_cases/C-file-filter/many}"
mkdir -p "$OUT"
for i in $(seq 1 6); do
  cat > "$OUT/module${i}.ts" << TS
export function fn${i}(x: number): number {
  return 100 / x // 未处理边界
}
TS
done
echo "已生成 6 个 TS 文件到 $OUT（配合 max_files: 3 验证 C3）"
