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
