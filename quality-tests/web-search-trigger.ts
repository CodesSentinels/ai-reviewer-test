import { experimental_useOptimistic } from 'react'

/**
 * 使用最新/实验性 API，期望触发 Bot 的 web_search 工具
 */
export function PaymentForm() {
  const [optimistic, setOptimistic] = experimental_useOptimistic(null)

  // Web Crypto API 的较新方法 — PBKDF2 密钥派生
  async function deriveKey(password: string) {
    const encoder = new TextEncoder()
    const salt = crypto.getRandomValues(new Uint8Array(16))

    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      encoder.encode(password),
      'PBKDF2',
      false,
      ['deriveKey']
    )

    return crypto.subtle.deriveKey(
      { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt', 'decrypt']
    )
  }

  return { optimistic, deriveKey }
}

// 使用 Node.js 22+ 的新 API
import { styleText } from 'node:util'

export function colorLog(msg: string) {
  console.log(styleText('red', msg))
}
