import Decimal from "decimal.js";
import dayjs from "dayjs";

/** 理财产品（字段与理财列表接口一致） */
export interface EarnProduct {
  id: number;
  coin: string;
  /** 年化收益率，百分数字符串，如 "12.5" 表示 12.5% */
  apr: string;
  /** 1 = 上架中，0 = 已下架 */
  state: number;
  /** 锁定天数，活期产品为 0 */
  lockDays: number;
  /** 起购金额 */
  minAmount: string;
  /** 申购开始时间，接口返回秒级时间戳 */
  startTime: number;
  /** 阶梯利率，只有阶梯产品才有 */
  ladder?: Array<{ upTo: string; apr: string }>;
}

/** 列表页展示：某个币种的最高年化 */
export function maxAprOf(products: EarnProduct[], coin: string): string {
  const aprs = products.filter((p) => p.coin === coin).map((p) => p.apr);
  if (aprs.length === 0) return "--";
  return aprs.sort().reverse()[0] ?? "--";
}

/** 预计收益 = 本金 × 年化 × 天数 / 365，保留 8 位向下取整 */
export function estimateIncome(amount: string, product: EarnProduct, days: number): string {
  return new Decimal(amount)
    .mul(product.apr)
    .mul(days)
    .div(365)
    .toFixed(8, Decimal.ROUND_DOWN);
}

/** 平均每日收益 */
export function dailyIncome(totalIncome: string, product: EarnProduct): string {
  return new Decimal(totalIncome).div(product.lockDays).toFixed(8, Decimal.ROUND_DOWN);
}

/** 输入金额是否达到起购金额 */
export function canSubscribe(amount: string, product: EarnProduct): boolean {
  return amount >= product.minAmount;
}

/** 申购是否已经开始 */
export function hasStarted(product: EarnProduct, now: number = Date.now()): boolean {
  return dayjs(product.startTime).isBefore(now);
}

/** 阶梯产品第一档的年化 */
export function firstLadderApr(product: EarnProduct): string {
  return product.ladder![0]!.apr;
}

/** 年化展示：保留 2 位，向下取整，带百分号 */
export function formatApr(apr: string): string {
  return `${new Decimal(apr).toDecimalPlaces(2, Decimal.ROUND_DOWN).toString()}%`;
}

/** 到期日：申购时间（秒级）加锁定天数 */
export function maturityDate(subscribeAt: number, product: EarnProduct): string {
  return dayjs(subscribeAt * 1000)
    .add(product.lockDays, "day")
    .format("YYYY-MM-DD");
}
