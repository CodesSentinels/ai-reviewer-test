import {ref} from 'vue'

export type FlagMap = Record<string, boolean>

/** 功能开关 composable。 */
export function useFeatureFlag(initial: FlagMap = {}) {
  const flags = ref<FlagMap>({...initial})

  function isEnabled(key: string): boolean {
    return flags.value[key] === true
  }

  function setFlag(key: string, value: boolean): void {
    flags.value[key] = value
  }

  return {flags, isEnabled, setFlag}
}
