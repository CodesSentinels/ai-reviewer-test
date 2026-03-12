/**
 * CartSummary.tsx — 购物车摘要组件
 *
 * 导入 calculator.ts 的 calculateTotal, TAX_RATE, formatPrice
 * 导入 formatter.ts 的 formatPercent
 * 导入 logger.ts 的 logInfo
 *
 * Case A/B/G 的引用检测目标文件
 */
import React from 'react'
import { calculateTotal, TAX_RATE, formatPrice } from '../utils/calculator'
import { formatPercent } from '../utils/formatter'
import { logInfo } from '../utils/logger'
import type { CartItem } from '../utils/calculator'

interface CartSummaryProps {
  items: CartItem[]
  onCheckout: () => void
}

export const CartSummary: React.FC<CartSummaryProps> = ({ items, onCheckout }) => {
  if (items.length === 0) {
    return <div className="cart-empty">购物车为空</div>
  }

  const subtotal = calculateTotal(items)
  const tax = subtotal * TAX_RATE
  const total = subtotal + tax

  logInfo('Cart summary rendered', `${items.length} items`)

  return (
    <div className="cart-summary">
      <h2>购物车摘要</h2>
      <ul>
        {items.map(item => (
          <li key={item.id}>
            {item.name} × {item.quantity} = {formatPrice(item.price * item.quantity)}
          </li>
        ))}
      </ul>
      <div className="totals">
        <p>小计: {formatPrice(subtotal)}</p>
        <p>税费 ({formatPercent(TAX_RATE)}): {formatPrice(tax)}</p>
        <p className="total">总计: {formatPrice(total)}</p>
      </div>
      <button onClick={onCheckout}>去结账</button>
    </div>
  )
}