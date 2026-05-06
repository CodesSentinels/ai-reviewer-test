#!/usr/bin/env bash
#
# apply-changes.sh — 一键应用迭代三 Linter/SAST 集成的端到端测试代码改动
#
# 用法:
#   cd ai-reviewer-test
#   bash test_cases/iteration3-linter-sast/code-changes/apply-changes.sh
#
# 做什么:
#   1. 创建测试分支 test/iter3-linter-sast
#   2. 拷贝 .codesentinel.yaml / eslint.config.js / biome.json 到仓库根
#   3. 在 utils/ 下新建 lint-test-cart.ts（含多种刻意问题）
#   4. 在 devDependencies 中安装 eslint + @biomejs/biome（如果尚未安装）
#   5. 提交代码 + 推送 + 创建 PR
#
# 注意:
#   - 先确认 .github/workflows/ai-reviewer.yml 已经引用了支持 Linter/SAST
#     的 ai-reviewer 分支（详见对应 docs）。
#   - 工具命令通过 `npx --no-install` 运行，所以包必须装在 node_modules。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$REPO_ROOT"
echo "工作目录: $(pwd)"

# 1. 创建分支
BRANCH="test/iter3-linter-sast"
echo "==> 创建/切换分支 ${BRANCH}"
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# 2. 拷贝配置文件到仓库根
echo "==> 写入 .codesentinel.yaml / eslint.config.js / biome.json"
cp "$SCRIPT_DIR/.codesentinel.yaml" .codesentinel.yaml
cp "$SCRIPT_DIR/eslint.config.js" eslint.config.js
cp "$SCRIPT_DIR/biome.json" biome.json

# 3. 拷贝测试源文件
echo "==> 写入 utils/lint-test-cart.ts"
cp "$SCRIPT_DIR/lint-test-cart.ts" utils/lint-test-cart.ts

# 4. 安装 lint 工具（仅当不存在时）
if [ ! -d node_modules/eslint ]; then
  echo "==> 安装 eslint"
  npm install --no-save --silent eslint@^9 || echo "(installing eslint failed; please run manually)"
fi
if [ ! -d node_modules/@biomejs/biome ]; then
  echo "==> 安装 @biomejs/biome"
  npm install --no-save --silent @biomejs/biome@^2 || echo "(installing biome failed; please run manually)"
fi

# 5. 提交并推送
git add \
  .codesentinel.yaml \
  eslint.config.js \
  biome.json \
  utils/lint-test-cart.ts
git commit -m "test(iter3): add linter/SAST integration scenarios

- introduce utils/lint-test-cart.ts with intentional ESLint/Biome violations
- enable .codesentinel.yaml (eslint + biome, prettier off)
- minimal eslint.config.js + biome.json"

echo "==> 推送分支并打开 PR"
git push -u origin "$BRANCH"

if command -v gh >/dev/null 2>&1; then
  gh pr create \
    --title "[iter3] Linter/SAST 集成端到端测试" \
    --body "测试入口。CI 触发后请在 PR 评论中验证 \"🧰 Static Analysis Summary\" 区块和逐评论的 \"🧰 Tools\" 标注是否正确。"
else
  echo "未检测到 gh CLI。请到 GitHub 上手动创建 PR。"
fi
