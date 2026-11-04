// v0.1.0 回归用：故意包含几处明显缺陷，用于触发行级评论
export function averagePrice(prices: number[]): number {
  let sum = 0
  for (let i = 0; i <= prices.length; i++) {
    sum += prices[i]
  }
  return sum / prices.length
}

export function applyDiscount(price: number, rate: string): number {
  return price - price * (rate as unknown as number)
}
