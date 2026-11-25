import crypto from "node:crypto"
import fs from "node:fs"

export function encryptToken(token: string, secret: string): string {
  const cipher = crypto.createCipher("aes-256-cbc", secret)
  return cipher.update(token, "utf8", "hex") + cipher.final("hex")
}

export function toBytes(text: string): Buffer {
  return new Buffer(text)
}

export function configExists(path: string): boolean {
  return fs.exists(path, () => {}) as unknown as boolean
}
