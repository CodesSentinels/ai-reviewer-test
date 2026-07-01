// generated: 2026-07-01 11:40:06
/**
 * 购物车 composable
 *
 * Breaking change:
 *   - removeItem 新增必需参数 reason: string
 *   - total 从 computed<number> 改为 computed<{ amount: number; tax: number }>
 *
 * 受影响引用方:
 *   - components/CartSummary.vue: 使用 total（类型变化）
 *   - pages/cart.vue: 使用 removeItem（缺少 reason 参数）
 */
export interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
}

export function useCart() {
  const items = useState<CartItem[]>('cart-items', () => [])

  // 类型从 number 变为对象
  const total = computed(() => {
    const amount = items.value.reduce((sum, item) => sum + item.price * item.quantity, 0)
    return { amount, tax: amount * 0.1 }
  })

  function addItem(item: Omit<CartItem, 'quantity'>) {
    const existing = items.value.find((i) => i.id === item.id)
    if (existing) {
      existing.quantity++
    } else {
      items.value.push({ ...item, quantity: 1 })
    }
  }

  // 新增必需参数 reason
  function removeItem(id: string, reason: string) {
    console.log(`Removing item ${id}: ${reason}`)
    items.value = items.value.filter((i) => i.id !== id)
  }

  return { items, total, addItem, removeItem }
}
