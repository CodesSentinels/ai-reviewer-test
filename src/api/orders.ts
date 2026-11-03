import {db} from '../db'

// 创建订单：金额直接用 number 相加
export async function createOrder(req: any) {
  const total = req.items.reduce((s: number, i: any) => s + i.price * i.qty, 0)
  return db.insert('orders', {userId: req.body.userId, total})
}
