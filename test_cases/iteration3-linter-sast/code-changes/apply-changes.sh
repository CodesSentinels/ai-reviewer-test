#!/usr/bin/env bash
#
# apply-changes.sh — 一键应用迭代三 Linter/SAST 集成的端到端测试代码改动
#
# 用法:
#   cd ai-reviewer-test
#   bash test_cases/iteration3-linter-sast/code-changes/apply-changes.sh
#
# 做什么:
#   1. 创建测试分支 feature/lint
#   2. 拷贝 .codesentinel.yaml / eslint.config.js / biome.json 到仓库根
#   3. 在 utils/ 下新建 lint-test-cart.ts（含多种刻意问题）
#   4. 把 eslint + @biomejs/biome 写入 devDependencies（`--save-dev`，
#      持久化到 package.json，确保 GitHub Actions runner 上 `npm install`
#      也能装上）
#   5. 提交代码（含更新后的 package.json / package-lock.json）+ 推送 + 创建 PR
#
# 注意:
#   - 先确认 .github/workflows/ai-reviewer.yml 已经引用了支持 Linter/SAST
#     的 ai-reviewer 分支（详见对应 docs）。
#   - ai-reviewer 通过 `npx --no-install` 运行 lint 工具，所以工具必须出现
#     在 runner 的 node_modules 里 — 这就需要它们在 package.json 中（或
#     workflow 显式安装）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$REPO_ROOT"
echo "工作目录: $(pwd)"

# 1. 创建分支
BRANCH="feature/lint"
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

# 4. 把 lint 工具写入 devDependencies（直接 patch package.json，避开 npm 解析）
#
#    历史教训：早期版本用 `npm install --save-dev --silent ... || echo "..."`，
#    --silent 隐藏了 npm 的错误输出，|| echo 吞掉了退出码，nuxt 生态的
#    ERESOLVE 冲突让 install 静默失败 → package.json 没动 → runner 上 npm
#    install 装不到工具 → 适配器全部 _unavailable_。
#
#    现在改为：直接读写 package.json（绕过依赖解析），然后用 --legacy-peer-deps
#    跑一次 install 把 node_modules 与可能的 lockfile 同步好，最后强制验证。
echo "==> 写入 devDependencies: eslint@^9 + @biomejs/biome@^2 → package.json"
node <<'NODE_EOF'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.devDependencies = pkg.devDependencies || {};
const wanted = {
  eslint: '^9.15.0',
  '@biomejs/biome': '^2.3.0'
};
let changed = false;
for (const [name, version] of Object.entries(wanted)) {
  if (pkg.devDependencies[name] !== version) {
    pkg.devDependencies[name] = version;
    changed = true;
  }
}
if (changed) {
  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
  console.log('  ✓ package.json updated');
} else {
  console.log('  ✓ package.json already has expected entries');
}
NODE_EOF

# 强制验证：防御 node 脚本静默失败（写入异常时会让此处报错并退出）
node -e '
const d = (require("./package.json").devDependencies) || {};
if (!d.eslint || !d["@biomejs/biome"]) {
  console.error("✗ devDependencies 缺少 eslint 或 @biomejs/biome");
  console.error("  当前 devDependencies:", JSON.stringify(d, null, 2));
  process.exit(1);
}
console.log("  ✓ verified: eslint=" + d.eslint + ", @biomejs/biome=" + d["@biomejs/biome"]);
'

# 让本地 node_modules 与 package.json 对齐（可选；workflow 上的 npm install 也会做这一步）
# --legacy-peer-deps 兜底 nuxt + eslint9 / vue 生态常见的 ERESOLVE 冲突
echo "==> 本地 npm install (--legacy-peer-deps，兜底 ERESOLVE)"
if ! npm install --legacy-peer-deps --no-audit --no-fund; then
  echo "⚠ 本地 npm install 失败 — 不影响 PR 触发后 CI runner 重装；" >&2
  echo "  但本地 npx eslint / biome 不可用。继续提交。" >&2
fi

# 5. 提交并推送（package.json 必须提交以持久化依赖，runner 才装得上）
git add \
  .codesentinel.yaml \
  eslint.config.js \
  biome.json \
  utils/lint-test-cart.ts \
  package.json
# package-lock.json 仅在存在时加入（项目原本无 lockfile，npm install 会生成一个）
[ -f package-lock.json ] && git add package-lock.json || true

# 重跑脚本时（feature/lint 已存在），暂存区可能没新变更——跳过 commit 而非报错
if git diff --cached --quiet; then
  echo "==> 暂存区无变更，跳过 git commit"
else
  git commit -m "test(iter3): add linter/SAST integration scenarios

- introduce utils/lint-test-cart.ts with intentional ESLint/Biome violations
- enable .codesentinel.yaml (eslint + biome, prettier off)
- add eslint@^9 + @biomejs/biome@^2 to devDependencies (so the runner installs them)
- minimal eslint.config.js + biome.json"
fi

echo "==> 推送分支并打开 PR"
git push -u origin "$BRANCH"

if command -v gh >/dev/null 2>&1; then
  gh pr create \
    --title "[iter3] Linter/SAST 集成端到端测试" \
    --body "测试入口。CI 触发后请在 PR 评论中验证 \"🧰 Static Analysis Summary\" 区块和逐评论的 \"🧰 Tools\" 标注是否正确。"
else
  echo "未检测到 gh CLI。请到 GitHub 上手动创建 PR。"
fi
