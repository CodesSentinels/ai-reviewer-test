#!/usr/bin/env bash
#
# 迭代三 · Phase 4 (Semgrep) 端到端测试 fixture 生成脚本
#
# 用途:
#   验证 ai-reviewer 的 SemgrepAdapter（pip 安装策略）能：
#     1. 在 runner 上从 pip 装好 semgrep 到沙箱 /tmp/ai-reviewer-lint-tools/python-tools/
#     2. 用 `--config=p/default` 扫描出常见的安全问题
#     3. 把 finding 注入 LLM Prompt + 评论尾部 🧰 Tools 卡片
#     4. PR 摘要表新增一行 `Semgrep <version>`
#
# 与现有 Phase 1 测试 (run-iter3-lint-eslint-biome.sh) 同款 fresh-file 策略：
#   新分支 + 新文件，整份文件每一行都是变更行，所有 Semgrep finding 都进窗口。
#
# 用法:
#   cd ai-reviewer-test
#   bash docs/run-iter3-semgrep.sh                          # 默认从 main 派生新分支
#   BASE=main bash docs/run-iter3-semgrep.sh                # 显式指定 base
#   BRANCH=feature/my-semgrep bash docs/run-iter3-semgrep.sh
#   NO_PUSH=1 bash docs/run-iter3-semgrep.sh                # 只本地提交，不推送
#
# 重要前置:
#   1. 在 .github/workflows/ai-reviewer.yml 的 `with:` 块加 **enable_semgrep: true**
#      （Phase 4 默认是关的，不加这行 SemgrepAdapter 不会跑）
#   2. 想换规则集时，再加 `semgrep_config: 'p/security-audit'` 之类（默认 p/default）
#

set -euo pipefail

BASE="${BASE:-main}"
BRANCH="${BRANCH:-feature/lint-semgrep-cases}"
NO_PUSH="${NO_PUSH:-0}"
# 用 .ts 文件 —— ai-reviewer-test 是 Nuxt/TS 项目，新增 .py 会被 path_filters/语言识别忽略，
# 导致 SemgrepAdapter 的 targets 为空、scan 直接 short-circuit → 评论区什么都不会出现。
# semgrep `p/default` 对 JS/TS 也有大量 SAST 规则覆盖。
FIXTURE_PATH="utils/sec-test-semgrep.ts"

# ── 健壮性检查 ──────────────────────────────────────────────────────────────
if [[ ! -f package.json ]] || ! grep -q '"name"' package.json; then
  echo "✗ 必须在 ai-reviewer-test 仓库根目录运行" >&2
  exit 1
fi
if [[ ! -d .git ]]; then
  echo "✗ 当前目录不是 git 仓库" >&2
  exit 1
fi

echo "============================================="
echo "  迭代三 · Phase 4 Semgrep 集成测试（fresh-file 方案）"
echo "  base:    ${BASE}"
echo "  branch:  ${BRANCH}"
echo "  fixture: ${FIXTURE_PATH}"
echo "============================================="

# ── 1. 切到新分支 ──────────────────────────────────────────────────────────
echo ""
echo "▸ Step 1: 从 ${BASE} 派生新分支 ${BRANCH}"
git fetch origin "${BASE}" --quiet || true
if git show-ref --quiet "refs/heads/${BRANCH}"; then
  echo "  分支已存在，切过去并重置到 origin/${BASE}（避免历史包袱）"
  git checkout "${BRANCH}"
  git reset --hard "origin/${BASE}"
else
  git checkout -b "${BRANCH}" "origin/${BASE}"
fi

# ── 2. 写入 fixture 文件 ───────────────────────────────────────────────────
echo ""
echo "▸ Step 2: 写入 ${FIXTURE_PATH}"
mkdir -p "$(dirname "${FIXTURE_PATH}")"
cat > "${FIXTURE_PATH}" <<'TS_FIXTURE'
/**
 * sec-test-semgrep.ts — 专攻 Semgrep p/default 在 JS/TS 上的测试 fixture
 *
 * 每个函数刻意触发一类 SAST 问题（多数对应 javascript.lang.security.audit.*
 * 规则族），用于验证：
 *   - SemgrepAdapter 在 .ts 文件上能跑通（不依赖 Python 文件）
 *   - finding 注入 LLM Prompt，AI 评论尾部出现 🧰 Tools 卡片
 *   - 跨工具去重：与 ESLint/Biome 互不重叠（semgrep 关注安全模式）
 *   - PR 摘要表多一行 Semgrep <version>
 *
 * 各 bug 间隔 ≥ 5 行，避免被 ±3 变更行窗口聚簇。
 *
 * ⚠️ 不要在生产代码中复制 —— 它们故意是漏洞。
 */

import {execSync} from 'child_process'
import {createHash} from 'crypto'

/* ────────────────────────────────────────────────────────────────────────
 * Bug 1：eval(用户输入) —— 任意代码执行
 *   Semgrep: javascript.lang.security.audit.eval-detected
 * ────────────────────────────────────────────────────────────────────── */
export function runFormula(expr: string): unknown {
  return eval(expr)
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 2：new Function(userInput) —— eval 的等价物
 *   Semgrep: javascript.lang.security.audit.non-literal-fs-filename / new-function
 * ────────────────────────────────────────────────────────────────────── */
export function dynamicLogic(body: string): Function {
  return new Function('args', body)
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 3：child_process.execSync 拼用户输入 —— 命令注入
 *   Semgrep: javascript.lang.security.audit.detect-child-process /
 *            javascript.lang.security.audit.dangerous-exec
 * ────────────────────────────────────────────────────────────────────── */
export function listDirectory(dir: string): string {
  return execSync(`ls -la ${dir}`).toString()
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 4：MD5 用于密码哈希 —— 弱加密
 *   Semgrep: javascript.lang.security.audit.md5-used-as-password /
 *            javascript.lang.security.audit.detect-md5
 * ────────────────────────────────────────────────────────────────────── */
export function passwordDigest(pw: string): string {
  return createHash('md5').update(pw).digest('hex')
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 5：硬编码 AWS Secret Key —— secrets 规则
 *   Semgrep: generic.secrets.security.detected-aws-secret-access-key
 *   (示例值取自 AWS 官方文档，是公认的 fake key 字符串)
 * ────────────────────────────────────────────────────────────────────── */
export const AWS_SECRET_ACCESS_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'


/* ────────────────────────────────────────────────────────────────────────
 * Bug 6：Math.random 用于安全令牌 —— 弱随机
 *   Semgrep: javascript.lang.security.audit.math-random-security
 * ────────────────────────────────────────────────────────────────────── */
export function generateSessionToken(): string {
  return Math.random().toString(36).substring(2)
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 7：require(用户输入) —— 任意模块加载
 *   Semgrep: javascript.lang.security.audit.non-literal-require
 * ────────────────────────────────────────────────────────────────────── */
export function loadPlugin(name: string): unknown {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  return require(name)
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 8：innerHTML = 用户字符串 —— DOM XSS
 *   Semgrep: javascript.browser.security.audit.dom-based-xss
 * ────────────────────────────────────────────────────────────────────── */
export function renderUserHtml(el: HTMLElement, html: string): void {
  el.innerHTML = html
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 9：硬编码 JWT 密钥 —— secrets 规则
 *   Semgrep: javascript.lang.security.audit.hardcoded-secret
 * ────────────────────────────────────────────────────────────────────── */
export const JWT_SIGNING_SECRET = 'my-super-secret-jwt-key-do-not-share-123'
TS_FIXTURE

echo "  ✓ 已写入 $(wc -l < "${FIXTURE_PATH}") 行"

# ── 3. 提交 ────────────────────────────────────────────────────────────────
echo ""
echo "▸ Step 3: git add + commit"
git add "${FIXTURE_PATH}"
git add "./.github/workflows/ai-reviewer.yml"  # 提醒用户别忘了改 workflow
if git diff --cached --quiet; then
  echo "  ⚠ 没有变更可提交（fixture 已经存在且内容相同）"
else
  git commit -m "test(iter3): add Semgrep SAST fixture (Phase 4, TypeScript)

新增 utils/sec-test-semgrep.ts，包含 9 条 JS/TS SAST 漏洞模式：
  - Bug 1: eval(userInput)
  - Bug 2: new Function(userInput)
  - Bug 3: child_process.execSync 拼用户输入
  - Bug 4: MD5 用于密码哈希
  - Bug 5: 硬编码 AWS 密钥
  - Bug 6: Math.random 用作安全令牌
  - Bug 7: require(userInput) 非字面量
  - Bug 8: innerHTML = userInput (DOM XSS)
  - Bug 9: 硬编码 JWT 密钥

各 bug 间隔 ≥ 5 行，避免被变更行窗口聚簇。

期望验证：
  - SemgrepAdapter pip 安装成功（首次冷启 +15-30s）
  - PR 摘要表多一行 'Semgrep <version>'
  - 多条 finding 出现在 PR 行级评论（带 🧰 Tools 卡片）

前置：workflow 的 with: 块需加 \`enable_semgrep: true\`
（Phase 4 默认禁用，避免给所有用户增加 15-30s 冷启动）"
fi

# ── 4. 推送 ────────────────────────────────────────────────────────────────
if [[ "${NO_PUSH}" == "1" ]]; then
  echo ""
  echo "▸ NO_PUSH=1，跳过推送"
  echo "  手动 push: git push -u origin ${BRANCH}"
else
  echo ""
  echo "▸ Step 4: 推送到远端"
  git push -u origin "${BRANCH}" --force-with-lease
fi

echo ""
echo "============================================="
echo "  Done."
echo ""
echo "  下一步（手动）："
echo "    1. 在 .github/workflows/ai-reviewer.yml 的 with: 块加："
echo "         enable_semgrep: true"
echo "       （可选）改规则集（建议先用默认 p/default 确认能跑通）："
echo "         semgrep_config: 'p/security-audit'"
echo "    2. 到 GitHub 创建 PR (base=${BASE}, head=${BRANCH})"
echo "    3. 等 GitHub Actions 跑完 review，按顺序看日志确认到底哪步出问题："
echo ""
echo "     ── 日志诊断序列 ─────────────────────────────────────────────"
echo "       a) 'lint: N/M adapters enabled — [..., semgrep:on(override=true), ...]'"
echo "          ↑ 没看到 semgrep:on → 是 enable_semgrep 没生效（workflow 未改 / "
echo "            修改没 push 到 PR 分支）"
echo ""
echo "       b) 'lint/installer[pip]: installing semgrep (...) → /tmp/.../python-tools'"
echo "          'lint/installer[pip]: semgrep ready at ... after <N>ms'"
echo "          ↑ 第二行没出现 → pip 装包失败，找 [pip]: pip exit=... 看 stderr"
echo ""
echo "       c) 'lint/semgrep[detect]: ready in <N>ms — bin=..., version=..., config=p/default'"
echo "          ↑ 没出现 → semgrep --version 失败（看 [detect]: --version failed 行）"
echo ""
echo "       d) 'lint/semgrep[scan]: start config=p/default, files=N — sample: ...'"
echo "          'lint/semgrep[scan]: returned in <N>ms — exit=..., stdout_len=..., stderr_len=...'"
echo "          ↑ files=0 → 沙箱里 targets 为空（路径/扩展名都不匹配，正常情况下不会到这步）"
echo ""
echo "       e) 'lint/semgrep[scan]: parsed N finding(s) from M raw result(s)'"
echo "          ↑ N=0 但你期望有 → 多半是 'no parseable JSON in stdout' 或 'semgrep-level error'"
echo "            前者通常是 semgrep 拉规则失败（公司网络挡了 semgrep.dev）"
echo "            后者是 semgrep 自己报错，stderr_first 字段会写明"
echo ""
echo "    4. 最终通过条件（按理想流程）："
echo "       - PR 摘要中多一行 'Semgrep <version>'，Errors 列 ≥ 5"
echo "       - 9 处 bug 至少有 5 处得到行级评论 + 🧰 Tools 卡片标注 Semgrep"
echo "============================================="
