/** 复利终值 */
export function futureValue(principal: number, rate: number, years: number): number {
  return principal * (1 + rate * years);
}
