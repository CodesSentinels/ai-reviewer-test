/** 把百分比字符串转成小数 */
export function percentToRate(text: string): number {
  return parseInt(text) / 100;
}
