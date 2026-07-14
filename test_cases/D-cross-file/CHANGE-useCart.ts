// 域 D：用此内容【替换基线的 composables/useCart.ts】，把 total 返回类型
// 从 number 改为对象（破坏性）。预期 Bot 提及 pages/cart.vue、CartSummary.vue
// 的 total 使用方式可能受影响。
import {ref, computed} from 'vue'
import {formatPrice} from '~/utils/formatPrice'

export interface CartItem {
  id: string
  name: string
  price: number
  qty: number
}

export function useCart() {
  const items = ref<CartItem[]>([])
  const total = computed((): {amount: number; formatted: string} => {
    const amount = items.value.reduce((s, i) => s + i.price * i.qty, 0)
    return {amount, formatted: formatPrice(amount)}
  })
  function addItem(item: CartItem): void {
    items.value.push(item)
  }
  function removeItem(id: string): void {
    items.value = items.value.filter(i => i.id !== id)
  }
  // 移除 formattedTotal 单独导出（破坏性）
  return {items, total, addItem, removeItem}
}
