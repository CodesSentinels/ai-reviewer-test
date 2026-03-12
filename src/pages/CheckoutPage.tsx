/**
 * CheckoutPage.tsx — 结账页面
 *
 * 导入 calculator.ts 的 TAX_RATE
 * 导入 formatter.ts 的 formatPercent
 *
 * Case B: TAX_RATE 引用目标
 */
import React from 'react'
import { CartSummary } from '../components/CartSummary'
import { CheckoutForm } from '../components/CheckoutForm'
import { TAX_RATE } from '../utils/calculator'
import { formatPercent } from '../utils/formatter'
import type { CartItem } from '../utils/calculator'

interface CheckoutPageProps {
  items: CartItem[]
}

export const CheckoutPage: React.FC<CheckoutPageProps> = ({ items }) => {
  const handleSubmit = (data: { total: number; address: string }) => {
    console.log('Order submitted:', data)
  }

  return (
    <div className="checkout-page">
      <h1>确认订单</h1>
      <p className="tax-notice">
        当前税率: {formatPercent(TAX_RATE)}
      </p>
      <div className="checkout-layout">
        <CartSummary items={items} onCheckout={() => {}} />
        <CheckoutForm items={items} onSubmit={handleSubmit} />
      </div>
    </div>
  )
}