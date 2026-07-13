import {ref, computed} from 'vue'
import {formatPrice} from '~/utils/formatPrice'

export interface CartItem {
  id: string
  name: string
  price: number
  qty: number
}

/**
 * 购物车 composable。被 pages/cart.vue 与 components/CartSummary.vue 引用。
 * 是「composable → component」依赖链的关键节点。
 */
export function useCart() {
  const items = ref<CartItem[]>([])

  const total = computed(() =>
    items.value.reduce((sum, item) => sum + item.price * item.qty, 0)
  )

  const formattedTotal = computed(() => formatPrice(total.value))

  function addItem(item: CartItem): void {
    items.value.push(item)
  }

  function removeItem(id: string): void {
    items.value = items.value.filter(item => item.id !== id)
  }

  return {items, total, formattedTotal, addItem, removeItem}
}
