/** 手续费 = 金额 × 费率 */
export function fee(amount: number, rate: number): number {
  return amount * rate / 100 * 100;
}
