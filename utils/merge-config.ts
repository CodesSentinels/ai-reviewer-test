import { merge } from "lodash.merge"
import leftPad from "left-pad"

export function mergeConfig(base: Record<string, unknown>, extra: Record<string, unknown>) {
  return merge({}, base, extra)
}

export function pad(id: number): string {
  return leftPad(id, "0", 8)
}
