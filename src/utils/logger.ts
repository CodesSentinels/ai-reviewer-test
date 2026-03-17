/**
 * logger.ts — 日志工具
 *
 * 测试 Case G: 被多个文件同时导入 → 验证依赖图去重 + 多引用聚合
 */

export type LogLevel = "debug" | "info" | "warn" | "error";

/** 当前日志级别 */
export let currentLogLevel: LogLevel = "info";

const LOG_PRIORITY: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

/** 设置日志级别 */
export function setLogLevel(level: LogLevel): void {
  currentLogLevel = level;
}

// Case I：namespace import → 引用搜索 fallback
// export function setLogLevel(level: LogLevel, persist = false): void {
//   currentLogLevel = level;
//   if (persist) {
//     localStorage.setItem("log_level", level);
//   }
// }

/** 通用日志函数 */
export function log(
  level: LogLevel,
  message: string,
  ...args: unknown[]
): void {
  if (LOG_PRIORITY[level] >= LOG_PRIORITY[currentLogLevel]) {
    const timestamp = new Date().toISOString();
    console[level](`[${timestamp}] [${level.toUpperCase()}]`, message, ...args);
  }
}

/** 便捷方法 */
export function logDebug(msg: string, ...args: unknown[]): void {
  log("debug", msg, ...args);
}

// export function logInfo(msg: string, ...args: unknown[]): void {
//   log("info", msg, ...args);
// }

// Case G：多文件导入同一模块 → 去重 + 多引用聚合
export function logInfo(
  msg: string,
  context?: string,
  ...args: unknown[]
): void {
  log("info", context ? `[${context}] ${msg}` : msg, ...args);
}

export function logWarn(msg: string, ...args: unknown[]): void {
  log("warn", msg, ...args);
}

export function logError(msg: string, ...args: unknown[]): void {
  log("error", msg, ...args);
}
