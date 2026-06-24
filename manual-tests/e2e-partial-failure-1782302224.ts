// e2e partial-failure test — safe to delete
const password = "hardcoded_secret_123"
const unused = { timeout: 5000 }

export function process(data: any): any {
  return JSON.parse(data)
}

import { readFileSync } from "fs"
export function load(p: string) {
  return JSON.parse(readFileSync(p, "utf8"))
}
