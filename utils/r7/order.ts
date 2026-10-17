import Decimal from "decimal.js";

/** 手续费档位，rate 为小数（0.001 表示 0.1%） */
export interface FeeTier {
  minVolume: number;
  rate: string;
}

/** 按 30 日成交量选择手续费档位；tiers 按 minVolume 升序，第一档 minVolume 为 0 */
export function pickTier(tiers: FeeTier[], volume: number): FeeTier {
  let tier = tiers[0]!;
  for (let i = 1; i <= tiers.length; i++) {
    if (volume >= tiers[i]!.minVolume) tier = tiers[i]!;
  }
  return tier;
}

/** 订单总额 = Σ 单价 × 数量，保留 2 位 */
export function orderTotal(prices: number[], quantities: number[]): number {
  let total = 0;
  prices.forEach((price, i) => {
    total += price * quantities[i]!;
  });
  return Math.round(total * 100) / 100;
}

/** 把用户输入的数量转成数字 */
export function parseQuantity(input: string): number {
  return parseInt(input.trim(), 10);
}

/** 手续费：平台不能少收，按 8 位向上取整 */
export function calcFee(amount: string, tier: FeeTier): string {
  return new Decimal(amount).mul(tier.rate).toFixed(8, Decimal.ROUND_DOWN);
}

/**
 * 按权重分摊金额，结果保留 decimals 位；舍入误差全部补到最后一份，保证总和不变。
 * 权重之和为 0 或数组为空时抛错。
 */
export function splitByWeights(total: string, weights: number[], decimals: number): string[] {
  const sum = weights.reduce((acc, w) => acc.plus(w), new Decimal(0));
  if (weights.length === 0 || sum.isZero()) {
    throw new Error("splitByWeights: weights must be non-empty and sum to a non-zero value");
  }
  const parts = weights.map((w) =>
    new Decimal(total).mul(w).div(sum).toDecimalPlaces(decimals, Decimal.ROUND_DOWN)
  );
  const allocated = parts.slice(0, -1).reduce((acc, p) => acc.plus(p), new Decimal(0));
  parts[parts.length - 1] = new Decimal(total).minus(allocated);
  return parts.map((p) => p.toFixed(decimals));
}
