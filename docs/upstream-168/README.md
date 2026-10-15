# ai-reviewer#168：给 dist/ 加“新鲜度”CI 检查——操作步骤

面向：ai-reviewer 的维护者（你本人操作）。本目录里的文件都已在 ai-reviewer 的真实历史上验证过，可以直接复制使用。

## 要解决什么

GitHub Action 运行的是 `dist/index.js`，不是源码。现有的 `SOURCE_SHA` 校验（`.gitlab-ci.yml` 的 CI-013）只保证“SOURCE_SHA 是当前提交的祖先”，挡得住伪造 SHA，但挡不住“dist 落后源码”：落后 45 个提交也是祖先。

新增的检查比较的是：`dist/SOURCE_SHA` 与当前 HEAD 之间，**参与打包的输入文件**（`src/`、锁文件、`tsconfig.json`、`scripts/check-bundle-licenses.js`）有没有变化。有变化就说明 dist 落后，必须重新打包。

为什么不要求 `SOURCE_SHA === HEAD`：写入 SOURCE_SHA 时那个提交还不包含这次写入本身，后面的“重新打包 dist”提交和 PR 合并产生的 merge commit 都会让二者不相等（CI-013 的注释里已经说明）。所以比较“输入文件有没有变”，而不是“提交相不相等”。

## 文件清单

| 本目录文件                 | 复制到 ai-reviewer 仓库的位置        | 作用                                     |
| -------------------------- | ------------------------------------ | ---------------------------------------- |
| `check-dist-fresh.js`      | `scripts/check-dist-fresh.js`        | 检查脚本（零依赖，Node 即可运行）        |
| `check-dist-fresh.test.ts` | `__tests__/check-dist-fresh.test.ts` | 11 条单测，在临时 git 仓库里模拟各种状态 |
| `dist-fresh.yml`           | `.github/workflows/dist-fresh.yml`   | GitHub 上的检查                          |
| `repack-dist.yml`          | `.github/workflows/repack-dist.yml`  | **可选**：合入后自动重新打包并提交 dist  |

## 已验证过的行为（在 ai-reviewer 的真实历史上跑过）

| 检出的提交                            | dist/SOURCE_SHA | 结果                                                                               |
| ------------------------------------- | --------------- | ---------------------------------------------------------------------------------- |
| `0a63eb9`（我们发现问题时的 develop） | `1a6f6606`      | **失败**：落后 45 个提交，38 个打包输入文件有变化                                  |
| `9f20f5b`（PR #167 合入后）           | `66468ab2`      | **失败**：`src/prompts.ts`、`src/review.ts` 有变化（上游 `b3cf8e2` 没打包进 dist） |
| `24c8769`（重新打包之后）             | `9f20f5b1`      | 通过                                                                               |
| `4684cad`（当前 develop）             | `a6028a02`      | 通过                                                                               |

退出码：`0` 新鲜；`1` dist 落后；`2` 无法判断（SOURCE_SHA 缺失、格式不对、不是已知提交、不是祖先）。

## 步骤

### 第 1 步：新建分支，放入文件

```bash
cd <ai-reviewer 仓库>
git switch develop && git pull --ff-only origin develop
git switch -c chore/dist-fresh-check

cp <本目录>/check-dist-fresh.js        scripts/check-dist-fresh.js
cp <本目录>/check-dist-fresh.test.ts   __tests__/check-dist-fresh.test.ts
cp <本目录>/dist-fresh.yml             .github/workflows/dist-fresh.yml
# repack-dist.yml 先不要复制，见第 7 步
```

### 第 2 步：本地验证

```bash
npx prettier --check scripts/check-dist-fresh.js __tests__/check-dist-fresh.test.ts
npx jest __tests__/check-dist-fresh.test.ts --no-coverage     # 预期 11 条通过
node scripts/check-dist-fresh.js; echo "exit=$?"              # 在当前 develop 上预期 exit=0
```

再故意验证“会失败”：

```bash
echo "// x" >> src/main.ts && git commit -qam "tmp" && node scripts/check-dist-fresh.js; echo "exit=$?"   # 预期 exit=1，列出 src/main.ts
git reset -q --hard HEAD~1                                                                               # 撤销这个临时提交
```

### 第 3 步：提交并开 PR（目标 develop）

commit 消息：`ci: 新增 dist 新鲜度检查，防止 dist 落后于源码（ai-reviewer#168）`

```bash
git add scripts/check-dist-fresh.js __tests__/check-dist-fresh.test.ts .github/workflows/dist-fresh.yml
git commit -m "ci: 新增 dist 新鲜度检查，防止 dist 落后于源码（ai-reviewer#168）"
git push -u origin chore/dist-fresh-check
gh pr create --base develop --title "ci: 新增 dist 新鲜度检查（#168）" --body "见 #168。新增 scripts/check-dist-fresh.js、11 条单测和 dist-fresh workflow。"
```

这个 PR 只新增脚本、测试和 workflow，没有改 `src/` 和锁文件，所以合入后 develop 的 dist 仍然新鲜，检查是绿的。

### 第 4 步：合入后确认 push 检查为绿

在 Actions 页面看 `dist-fresh` 在 develop 上的这次运行，预期通过。

### 第 5 步：把检查设为 main 的必需检查（关键一步）

GitHub → 仓库 Settings → Branches（或 Rules）→ main 的保护规则 → Require status checks to pass before merging → 勾选 `dist-fresh`。
这样“develop → main”的发布 PR 在 dist 落后时无法合并，这才是 #168 真正要拦住的地方。

> 如果这个检查名字搜不到：先让 workflow 在 PR 上跑一次，状态检查名才会出现在可选列表里。

### 第 6 步：演练一遍完整流程（确认真的拦得住）

1. 开一个临时分支，改一行 `src/` 里的代码，提 PR 到 develop 并合入（或直接在测试分支上做）。
2. 此时 develop 上的 `dist-fresh` 预期**变红**，日志列出变化的文件，提示 `npm run build && npm run package`。
3. 执行重新打包并提交：
   ```bash
   npm run build && npm run package
   git add dist && git commit -m "chore: 重新打包 dist（对应 <源码提交 SHA>）" && git push origin develop
   ```
4. `dist-fresh` 恢复绿色。
5. 此时再开 develop → main 的 PR：必需检查应为绿，可以合并。

### 第 7 步（可选）：自动重新打包

手工提交“重新打包 dist”容易漏，这次的 #167、#174 都是事后补的。如果允许 `github-actions[bot]` 直接推送 develop，可以复制 `repack-dist.yml`：

- 它只在 `src/**`、锁文件、`tsconfig.json`、`scripts/check-bundle-licenses.js` 变化的 push 上触发，打包后自动提交 dist，消息格式沿用 `chore: 重新打包 dist（对应 <SHA>）`；
- 前提：develop 没有“必须经 PR 才能推送”的保护，或者给 bot 开了绕过；做不到就不要启用；
- 启用后，第 5 步的必需检查依然保留，作为兜底。

### 第 8 步（可选）：GitLab 侧同样检查

在 `.gitlab-ci.yml` 里，CI-013 那段祖先校验之后加一行 `node scripts/check-dist-fresh.js`（该 job 已经设了 `GIT_DEPTH: '0'`，满足完整历史的要求）。

## 注意事项与取舍

- **PR 到 develop 不检查**：检查只放在“PR 到 main”和“push 到 develop/main”。原因是你们的惯例是源码合入后再单独提交“重新打包 dist”，如果在 PR 到 develop 时就要求新鲜，每个改了 `src/` 的 PR 都会被卡住。
- **`package.json` 不在输入列表里**：依赖变化一定同时改锁文件；而新增 npm script 这类改动不影响打包产物，放进去会产生误报。如果你们的 `package.json` 里有影响打包的字段（比如 `engines`），可以按需加回 `BUILD_INPUTS`。
- **需要完整历史**：GitHub Actions 里 checkout 必须 `fetch-depth: 0`，浅克隆会得到退出码 2（“不是已知提交”）。
- **输入列表是白名单**：以后新增会影响打包产物的目录（例如新的 `bundle/` 配置），要同步加到 `BUILD_INPUTS`，否则那里的改动不会被识别为落后。
- **这个检查不保证 dist 内容确实是由该源码构建出来的**（需要可复现构建才能做到）。它回答的问题是“源码有没有在 dist 之后变过”，这正是 #168 的缺口。
