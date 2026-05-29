#!/usr/bin/env bash
#
# 迭代三 · Phase 4 Semgrep —— 扩展 JS/TS 漏洞测试 fixture 生成脚本
#
# 目的:
#   在已有 sec-test-semgrep.ts（9 条基础漏洞）之外，再加 10 条覆盖**不同
#   漏洞类别**的 JS/TS SAST 模式，进一步验证：
#     - Semgrep 对 Express/Crypto/JWT/TLS/secrets 等多家族规则的覆盖
#     - 同一 Adapter 一次扫描多文件、不同 ruleId 的去重 / 排序
#     - `🧰 Tools` 卡片在多种 finding 上的渲染稳定性
#
# 与 run-iter3-semgrep.sh 的关系:
#   两个脚本互不影响，分别从 main 派生**不同的新分支**。可以单独跑、也可
#   以分别开两个 PR 对比。
#
# 用法:
#   cd ai-reviewer-test
#   bash docs/run-iter3-semgrep-extra.sh                       # 默认 base=main
#   BASE=main bash docs/run-iter3-semgrep-extra.sh
#   BRANCH=feature/my-extra-semgrep bash docs/run-iter3-semgrep-extra.sh
#   NO_PUSH=1 bash docs/run-iter3-semgrep-extra.sh             # 只本地提交，不推送
#
# 重要前置:
#   在 .github/workflows/ai-reviewer.yml 的 `with:` 块加 **enable_semgrep: true**
#   （Phase 4 默认禁用，详见 run-iter3-semgrep.sh 的 commit message）
#

set -euo pipefail

BASE="${BASE:-main}"
BRANCH="${BRANCH:-feature/lint-semgrep-extra-cases}"
NO_PUSH="${NO_PUSH:-0}"
FIXTURE_PATH="utils/sec-test-semgrep-2.ts"

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
echo "  迭代三 · Phase 4 Semgrep 扩展 JS/TS 漏洞测试"
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
 * sec-test-semgrep-2.ts — Semgrep p/default JS/TS 扩展漏洞测试 fixture
 *
 * 第二批：覆盖 sec-test-semgrep.ts 未触及的漏洞家族，包括 TLS、JWT、CORS、
 * 弱加密原语、路径遍历、Buffer 等。每条 bug 之间隔 ≥ 5 行，避免被 ±3
 * 变更行窗口聚簇。
 *
 * 验证目标：
 *   - Semgrep 对 Express / crypto / JWT / TLS / fs 等多家族规则的覆盖
 *   - 一次扫描产出多种 ruleId 时 PR 评论的呈现稳定性
 *   - CWE/OWASP 标签拼到 message 末尾（杠杆 E 的优化）
 *
 * 类型/包导入说明：
 *   本文件用 type-only 桩声明替代真实的 'express' / 'https' / 'jsonwebtoken' /
 *   'fs' 等模块，避免给 ai-reviewer-test 加 devDependency。所有写法保持
 *   与真实 API 语义一致，让 Semgrep 的 AST 模式匹配能命中。
 *
 * ⚠️ 不要在生产代码中复制 —— 它们故意是漏洞。
 */

/* eslint-disable @typescript-eslint/no-explicit-any, @typescript-eslint/no-unused-vars */

import {createCipher, createHash, createPrivateKey} from 'crypto'
import {readFile} from 'fs'
import {request as httpsRequest} from 'https'

// 桩：避免真实依赖 express / jsonwebtoken
type ExpressApp = {
  use(fn: any): void
  get(path: string, handler: (req: any, res: any) => void): void
}
declare const app: ExpressApp
declare const jwt: {
  verify(token: string, secret: string, opts?: {algorithms?: string[]}): unknown
  sign(payload: object, secret: string): string
}
declare function cors(opts: {origin: string | boolean}): any


/* ────────────────────────────────────────────────────────────────────────
 * Bug 10：setTimeout 第一个参数传字符串 —— 等价 eval
 *   Semgrep: javascript.lang.security.audit.dangerous-settimeout.dangerous-settimeout
 * ────────────────────────────────────────────────────────────────────── */
export function scheduleDangerousCode(code: string, delay: number): void {
  setTimeout(code, delay)
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 11：child_process.exec（callback 风格）拼用户输入
 *   与 Bug 3 (execSync) 是不同规则，验证 exec / execSync / spawn 各自命中
 *   Semgrep: javascript.lang.security.audit.detect-child-process.detect-child-process
 * ────────────────────────────────────────────────────────────────────── */
export function runUserCommand(userCmd: string): void {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const {exec} = require('child_process')
  exec(`ping -c 1 ${userCmd}`, (err: unknown, stdout: string) => {
    console.log(stdout)
  })
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 12：crypto.createCipher —— 无 IV 的对称加密
 *   createCipher 自 Node 10 已 deprecated；不接受 IV，密钥派生不安全。
 *   Semgrep: javascript.lang.security.audit.crypto.unsafe-cipher.unsafe-cipher
 * ────────────────────────────────────────────────────────────────────── */
export function legacyEncrypt(secret: string, key: string): Buffer {
  const cipher = createCipher('aes-256-cbc', key)
  return Buffer.concat([cipher.update(secret, 'utf8'), cipher.final()])
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 13：SHA-1 哈希用于敏感场景（不是 MD5，是另一规则）
 *   Semgrep: javascript.lang.security.audit.crypto.weak-hashes-sha1.weak-hashes-sha1
 * ────────────────────────────────────────────────────────────────────── */
export function legacyDigest(input: string): string {
  return createHash('sha1').update(input).digest('hex')
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 14：deprecated Buffer 构造器 —— 未初始化内存泄漏
 *   `new Buffer(size)` 自 Node 6 已 deprecated；返回未清零的内存
 *   Semgrep: javascript.lang.security.audit.detect-buffer-unsafe.detect-buffer-unsafe
 * ────────────────────────────────────────────────────────────────────── */
export function allocLegacyBuffer(size: number): Buffer {
  return new Buffer(size)
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 15：fs.readFile 的 filename 参数是用户输入 —— 路径遍历
 *   Semgrep: javascript.lang.security.audit.detect-non-literal-fs-filename
 * ────────────────────────────────────────────────────────────────────── */
export function loadUserFile(filename: string): void {
  readFile(`/var/data/${filename}`, 'utf8', (err, data) => {
    if (err) throw err
    console.log(data)
  })
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 16：HTTPS 请求关闭证书验证 —— 中间人攻击门户大开
 *   Semgrep: javascript.lang.security.audit.network.tls.tls-disable-cert-verify
 *            / disable-tls-verify
 * ────────────────────────────────────────────────────────────────────── */
export function fetchInsecure(url: string): void {
  const req = httpsRequest(url, {rejectUnauthorized: false}, () => {})
  req.end()
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 17：JWT verify 接受 `algorithms: ['none']` —— 签名绕过
 *   Semgrep: javascript.jwt.security.audit.jwt-none-alg.jwt-none-alg
 * ────────────────────────────────────────────────────────────────────── */
export function decodeUserToken(token: string, secret: string): unknown {
  return jwt.verify(token, secret, {algorithms: ['none']})
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 18：Express CORS 设置 origin: '*' —— 任意源跨域
 *   Semgrep: javascript.express.security.audit.cors-allow-all
 * ────────────────────────────────────────────────────────────────────── */
export function setupCors(): void {
  app.use(cors({origin: '*'}))
}


/* ────────────────────────────────────────────────────────────────────────
 * Bug 19：硬编码的 RSA 私钥 —— secrets 规则命中
 *   Semgrep: generic.secrets.security.detected-private-key
 *   （注：这是一段刻意构造的"看起来像私钥"的字符串；不是真实有效密钥）
 * ────────────────────────────────────────────────────────────────────── */
export const ENCRYPTION_PRIVATE_KEY = `-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKL
MNOPQRSTUVWXYZ0123456789+/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKL
-----END RSA PRIVATE KEY-----`
TS_FIXTURE

echo "  ✓ 已写入 $(wc -l < "${FIXTURE_PATH}") 行"

# ── 3. 提交 ────────────────────────────────────────────────────────────────
echo ""
echo "▸ Step 3: git add + commit"
git add "${FIXTURE_PATH}"
git add "./.github/workflows/ai-reviewer.yml" 2>/dev/null || true  # 如已修改 workflow 一并提交
if git diff --cached --quiet; then
  echo "  ⚠ 没有变更可提交（fixture 已存在且内容相同）"
else
  git commit -m "test(iter3): extra Semgrep JS/TS SAST fixture (Phase 4 wave 2)

新增 utils/sec-test-semgrep-2.ts，覆盖 sec-test-semgrep.ts 未触及的
10 类 JS/TS 漏洞家族：
  - Bug 10: setTimeout(string, n) eval-like
  - Bug 11: child_process.exec (callback 风格)
  - Bug 12: crypto.createCipher (无 IV，已 deprecated)
  - Bug 13: SHA-1 哈希 (与 MD5 是不同规则)
  - Bug 14: new Buffer(n) (deprecated 构造器)
  - Bug 15: fs.readFile 路径遍历 (非字面量 filename)
  - Bug 16: rejectUnauthorized:false (关闭 TLS 证书校验)
  - Bug 17: jwt.verify({algorithms:['none']}) (签名绕过)
  - Bug 18: cors({origin:'*'}) (任意源跨域)
  - Bug 19: 硬编码 RSA 私钥 (secrets 规则)

各 bug 间隔 ≥ 5 行，避免被变更行窗口聚簇。

期望验证：
  - Semgrep 对 Express / crypto / JWT / TLS / secrets 多家族规则的覆盖
  - 每条 finding 带 CWE / OWASP 标签 (LintResult.message 末尾)
  - 评论尾部 🧰 Tools 卡片正确渲染 ruleId

前置：workflow 的 with: 块需有 \`enable_semgrep: true\`"
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
echo "    1. 确认 .github/workflows/ai-reviewer.yml 的 with: 块已有："
echo "         enable_semgrep: true"
echo "    2. 到 GitHub 创建 PR (base=${BASE}, head=${BRANCH})"
echo "    3. 等 Actions 跑完 review，按下面 4 个维度验收："
echo ""
echo "       ── 验收检查 ──────────────────────────────────────────────"
echo "       a) PR 摘要表多一行 'Semgrep <version>'，Errors 列 ≥ 6"
echo "       b) 10 处 bug 至少 6 处得到行级评论 + 🧰 Tools 卡片"
echo "          （TLS / JWT / CORS / secrets 是 p/default 强项；setTimeout"
echo "           / Buffer / 非字面量 fs 可能因 ruleset 版本差异不一定全中）"
echo "       c) 评论 message 末尾可见 [CWE-XX, OWASP A0X:20XX - ...] 标签"
echo "       d) AI 评论正文里能引用 CWE/OWASP 编号 (杠杆 E 的优化生效)"
echo ""
echo "       若有 finding 0 进评论，按 docs/run-iter3-semgrep.sh 末尾的"
echo "       'a→e 日志诊断序列' 查 Actions 日志定位卡点"
echo "============================================="
