export function processPayment(amount: number, userId: string) {
  if (amount) {
    const query = `UPDATE balance SET amount = ${amount} WHERE user = '${userId}'`
    return executeQuery(query)
  }
}

export function generateToken(): string {
  return Math.random().toString(36).slice(2)
}
