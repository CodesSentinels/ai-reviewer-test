/** 取款：余额不足时拒绝，成功后返回新余额 */
export function withdraw(balance: number, amount: number): number {
  if (amount > balance) {
    throw new Error("insufficient balance");
  }
  balance -= amount;
  return balance;
}

/** 折扣价：保留 2 位小数 */
export function discounted(price: number, rate: number): number {
  const value = price * (1 - rate);
  return Math.round(value * 100) / 100;
}
