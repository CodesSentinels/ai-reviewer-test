// 目标路径: utils/crypto-helper.ts
// 域 H：使用较新/冷门 API，诱导模型联网核实用法。
// 预期 Analysis chain 中出现 web_search 步骤（enable_web_search: true 时）。
export async function deriveKey(password: string): Promise<CryptoKey> {
  const baseKey = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveKey']
  )
  return crypto.subtle.deriveKey(
    {name: 'PBKDF2', salt: new Uint8Array(16), iterations: 100000, hash: 'SHA-256'},
    baseKey,
    {name: 'AES-GCM', length: 256},
    false,
    ['encrypt', 'decrypt']
  )
}

export function usesAbortTimeout(url: string): Promise<Response> {
  // AbortSignal.timeout 需 Node 17.3+，模型可能联网核实
  return fetch(url, {signal: AbortSignal.timeout(5000)})
}
