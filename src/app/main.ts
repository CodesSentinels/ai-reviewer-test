/**
 * main.ts — 应用入口文件
 *
 * 测试 Case D: 入口文件修改 → isEntryPointFile 识别后跳过分析
 * 即使此文件有导出符号，由于是入口文件，不会被其他模块导入
 */
import type { CartItem } from "../utils/calculator";

import { createOrder } from "../services/orderService";
import { logInfo, setLogLevel } from "../utils/logger";

/** 应用版本号（导出但作为入口文件不应被追踪） */
export const APP_VERSION = "1.0.0";

/** 初始化应用 */
export async function initApp(): Promise<void> {
  setLogLevel("info");
  logInfo("App starting", `version=${APP_VERSION}`);
}

/** 模拟下单流程 */
export async function placeOrder(items: CartItem[]): Promise<void> {
  logInfo("Placing order...");
  const order = await createOrder(items);
  logInfo("Order placed", order.id);
}
