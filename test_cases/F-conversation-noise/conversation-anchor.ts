// 目标路径: utils/payment.ts
// 域 F 对话锚点：设计为「值得追问」的问题，供 3.1 对话测试。
export function processPayment(amount: number, userId: string) {
  if (amount) {
    const query = `UPDATE balance SET amount = ${amount} WHERE user = '${userId}'` // SQL 注入
    return executeQuery(query)
  }
}

declare function executeQuery(q: object): unknown
