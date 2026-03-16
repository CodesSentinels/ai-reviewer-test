/**
 * inventoryService.ts — 库存服务
 *
 * 通过 barrel file (utils/index.ts) 间接导入 calculator.ts 的函数
 *
 * 测试 Case H2: Barrel file 间接引用追踪
 * import { calculateTotal } from '../utils' → 解析到 utils/index.ts
 * → 步骤 5.5 识别 index.ts 为 barrel file，追踪到真实来源 calculator.ts
 * → calculateTotal 被修改时，本文件应被检测为间接消费者
 */
import { calculateTotal, formatPrice, logInfo } from '../utils'
import type { CartItem } from '../utils/calculator'

export interface InventoryCheck {
  itemId: string
  available: boolean
  estimatedValue: string
}

/** 评估库存价值 — 通过 barrel file 间接使用 calculateTotal */
export function evaluateInventoryValue(items: CartItem[]): string {
  const total = calculateTotal(items)
  logInfo('Inventory evaluated', `items=${items.length}, value=${total}`)
  return formatPrice(total)
}

/** 批量检查库存可用性 */
export function checkInventoryAvailability(
  items: CartItem[],
  stockMap: Map<string, number>,
): InventoryCheck[] {
  const totalValue = calculateTotal(items)
  logInfo('Inventory check', `totalValue=${totalValue}`)

  return items.map(item => {
    const stock = stockMap.get(item.id) ?? 0
    return {
      itemId: item.id,
      available: stock >= item.quantity,
      estimatedValue: formatPrice(item.price * item.quantity),
    }
  })
}
