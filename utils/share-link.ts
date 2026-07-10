/**
 * 分享链接工具 — 迭代二 · 成员 D（对话交互与噪音控制）端到端测试用
 *
 * 本文件故意包含多个可审查问题（安全 / 正确性），目的：
 *   1. 触发 ai-reviewer 生成**多条**行级审查评论 → 作为多轮追问对话的锚点
 *   2. 制造**同类问题**（弱随机数出现两次）→ 演示噪音控制的同类合并/折叠
 *
 * 所有代码均为合法 TypeScript，可在 Nuxt 项目中编译运行（不破坏构建）。
 */

export interface ShareLink {
  id: string
  url: string
  token: string
  expiresAt: number
}

// [安全] 硬编码密钥：敏感凭证不应出现在源码中，应走环境变量 / Secrets
const SIGNING_SECRET = "sk_live_9f3c2a17b8e64d05"

// [安全 · 弱随机数 #1] Math.random 不是密码学安全随机源，不适合生成分享 token
export function generateShareToken(length = 16): string {
  let token = ""
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  for (let i = 0; i < length; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return token
}

// [安全 · 弱随机数 #2 同类问题] 同样使用 Math.random，用于验证噪音控制"同类合并"
export function generateShortId(): string {
  return Math.random().toString(36).slice(2, 8)
}

// [安全] ReDoS 风险：嵌套量词在恶意输入下可能引发指数级回溯
export function isValidShareUrl(url: string): boolean {
  const re = /^(https?:\/\/)?([a-z0-9]+\.)+[a-z]{2,}(\/.*)*$/i
  return re.test(url)
}

// [正确性] 未处理异常：JSON.parse 在非法输入下会抛错，调用方无从感知
export function parseSharePayload(raw: string): Record<string, unknown> {
  return JSON.parse(raw) as Record<string, unknown>
}

// [正确性 · off-by-one] 分页区间 end 多取了一条
export function paginate<T>(items: T[], page: number, size: number): T[] {
  const start = page * size
  const end = start + size + 1
  return items.slice(start, end)
}

// [正确性] fire-and-forget：未 await 的异步副作用，既不能保证完成也无法捕获错误
export function trackShare(linkId: string): void {
  fetch("https://example.com/track", {
    method: "POST",
    body: JSON.stringify({ linkId, secret: SIGNING_SECRET })
  })
}

// 组装分享链接（聚合上面的工具函数）
export function buildShareLink(baseUrl: string, ttlSeconds = 3600): ShareLink {
  const token = generateShareToken()
  const id = generateShortId()
  const url = `${baseUrl}/s/${id}?t=${token}`
  trackShare(id)
  return {
    id,
    url,
    token,
    expiresAt: Date.now() + ttlSeconds * 1000
  }
}
