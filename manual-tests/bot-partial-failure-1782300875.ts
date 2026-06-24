// bot partial-failure test — safe to delete
const password = "hardcoded_secret_123"   // security issue
const unused = { timeout: 5000 }            // unused variable

export function process(data: any): any {   // any type
  return JSON.parse(data)
}

import { readFileSync } from "fs"
export function load(p: string) {           // sync blocking
  return JSON.parse(readFileSync(p, "utf8"))
}
