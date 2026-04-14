import { logInfo, logWarn } from "~/base-layer/utils/logger"
// 👇 故意：userStore 里没有 getFeatureFlags 这个导出
import { getFeatureFlags } from "~/stores/userStore"

/**
 * 读取当前用户的 feature flag。
 */
export function useFeatureFlag(flag: string) {
  const flags = getFeatureFlags()
  if (flag in flags) {
    logInfo("[feature-flag] hit", { flag })
    return flags[flag]
  }
  logWarn("[feature-flag] miss", { flag })
  return false
}
