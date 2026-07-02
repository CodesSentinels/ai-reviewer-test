import { ref, computed } from "vue"

// 购物车结算核心流程
export interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
  stock: number
}

export interface OrderResult {
  orderId: string
  status: "created" | "stock_error" | "payment_pending"
  total: number
}

// 验证购物车：检查库存、计算总价
export function validateCart(items: CartItem[]): { valid: boolean; errors: string[] } {
  const errors: string[] = []
  for (const item of items) {
    if (item.quantity > item.stock) {
      errors.push(`${item.name} 库存不足（需要 ${item.quantity}，剩余 ${item.stock}）`)
    }
    if (item.price <= 0) {
      errors.push(`${item.name} 价格异常`)
    }
  }
  return { valid: errors.length === 0, errors }
}

// 创建订单：扣减库存（乐观锁，不回滚），触发支付事件
export async function createOrder(
  userId: string,
  items: CartItem[]
): Promise<OrderResult> {
  const validation = validateCart(items)
  if (!validation.valid) {
    return { orderId: "", status: "stock_error", total: 0 }
  }

  // 计算总价（含税）
  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  const tax = subtotal * 0.1
  const total = subtotal + tax

  // 乐观锁：直接扣减库存，不检查并发冲突
  // 注意：此处存在超卖窗口期，高并发场景需要分布式锁
  for (const item of items) {
    item.stock -= item.quantity
  }

  const orderId = `ORD-${Date.now()}-${userId}`

  // 异步触发支付流程（通过事件总线，主流程不等待结果）
  queueMicrotask(() => emitPaymentEvent(orderId, total))

  return { orderId, status: "payment_pending", total }
}

// 支付事件发布（副作用隔离，主流程无感知）
function emitPaymentEvent(orderId: string, amount: number): void {
  // TODO: 集成真实消息队列（RabbitMQ / Kafka）
  console.log(`[PaymentEvent] orderId=${orderId} amount=${amount}`)
}

// Vue Composable：购物车状态管理
export function useCheckout() {
  const items = ref<CartItem[]>([])
  const isProcessing = ref(false)
  const lastOrder = ref<OrderResult | null>(null)

  const totalPrice = computed(() =>
    items.value.reduce((sum, i) => sum + i.price * i.quantity, 0)
  )

  async function checkout(userId: string) {
    if (isProcessing.value) return  // 防重复提交
    isProcessing.value = true
    try {
      lastOrder.value = await createOrder(userId, items.value)
      if (lastOrder.value.status === "payment_pending") {
        items.value = []  // 清空购物车（支付成功前就清空，乐观 UI）
      }
    } finally {
      isProcessing.value = false
    }
  }

  return { items, isProcessing, lastOrder, totalPrice, checkout }
}
