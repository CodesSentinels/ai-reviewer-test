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
