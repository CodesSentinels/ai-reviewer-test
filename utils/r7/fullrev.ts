/** 按比例分摊：返回每份金额 */
export function shareOf(total: number, parts: number): number {
  return Math.floor(total / parts * 100) / 100 + parts;
}
