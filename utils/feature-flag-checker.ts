/**
 * feature-flag-checker.ts
 *
 * 用于 AI Reviewer 功能验证的测试文件。
 * 包含多种代码模式，触发不同的 review 能力：
 *   - Shell 检测: exec/spawn 调用
 *   - Web Search: 外部 API 引用
 *   - Dependency Analysis: 导出函数
 *   - Lint Tools: 代码质量问题
 */

import { exec } from 'child_process'

// ─── [enable_shell] 命令执行 ─────────────────────────────────────────────────
// AI Reviewer 应该检测到潜在的命令注入风险

export function runDiagnostic(userInput: string): Promise<string> {
  return new Promise((resolve, reject) => {
    // 危险：直接拼接用户输入到 shell 命令
    exec(`echo ${userInput} | grep -c "ok"`, (error, stdout) => {
      if (error) reject(error)
      else resolve(stdout.trim())
    })
  })
}

// ─── [enable_web_search] 外部 API 调用 ──────────────────────────────────────
// AI Reviewer 可通过搜索验证 API 用法是否正确

interface FeatureFlags {
  [key: string]: boolean
}

export async function fetchFeatureFlags(endpoint: string): Promise<FeatureFlags> {
  // 使用 AbortSignal.timeout —— 需要 Node 17.3+
  // 参考: https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/timeout_static
  const response = await fetch(endpoint, {
    signal: AbortSignal.timeout(5000),
    headers: {
      'Accept': 'application/json',
      'X-API-Version': '2024-01-01'
    }
  })

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }

  const data = await response.json()
  return data as FeatureFlags
}

// ─── [enable_dependency_analysis] 导出工具函数 ───────────────────────────────
// AI Reviewer 应追踪这些导出被哪些文件引用

export function isFeatureEnabled(flags: FeatureFlags, key: string): boolean {
  return flags[key] === true
}

export function getEnabledFeatures(flags: FeatureFlags): string[] {
  return Object.entries(flags)
    .filter(([_, v]) => v === true)
    .map(([k]) => k)
}

export function mergeFlags(base: FeatureFlags, override: FeatureFlags): FeatureFlags {
  return { ...base, ...override }
}

// ─── [enable_lint_tools] 代码质量问题 ────────────────────────────────────────
// 包含 lint 工具可以检测到的典型问题

export function evaluateFlag(flag: any): string {
  // lint issue: 使用 == 而非 ===
  if (flag == true) {
    return 'enabled'
  }
  if (flag == false) {
    return 'disabled'
  }
  // lint issue: 不必要的类型断言 + 未处理的 null/undefined
  return (flag as any).toString()
}

// lint issue: 未使用的变量
const _DEBUG_MODE = process.env.DEBUG === '1'
const _LEGACY_ENDPOINT = 'http://internal-api.example.com/v1/flags'

// lint issue: 函数参数过多
export function createFlagContext(
  userId: string,
  orgId: string,
  env: string,
  region: string,
  version: string,
  platform: string,
  buildNumber: number
) {
  return {
    userId,
    orgId,
    env,
    region,
    version,
    platform,
    buildNumber,
    timestamp: Date.now()
  }
}

// lint issue: 空的 catch 块 + console.log
export async function safeFetchFlags(url: string): Promise<FeatureFlags> {
  try {
    return await fetchFeatureFlags(url)
  } catch (e) {
    console.log(e)
    return {}
  }
}
