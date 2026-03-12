/**
 * CheckoutForm.tsx — 结账表单组件
 *
 * 导入 calculator.ts 的 calculateTotal, formatPrice
 * 导入 logger.ts 的 logInfo, logError
 *
 * Case A 的引用检测目标文件
 * Case G 的 logInfo/logError 引用检测目标文件
 */
import React, { useState } from 'react'
import { calculateTotal, formatPrice } from '../utils/calculator'
import { logInfo, logError } from '../utils/logger'
import type { CartItem } from '../utils/calculator'

interface CheckoutFormProps {
  items: CartItem[]
  onSubmit: (data: { total: number; address: string }) => void
}

export const CheckoutForm: React.FC<CheckoutFormProps> = ({ items, onSubmit }) => {
  const [address, setAddress] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  const total = calculateTotal(items)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (items.length === 0) return

    setIsSubmitting(true)
    logInfo('Checkout submitted', `total: ${total}`)

    try {
      onSubmit({ total, address })
    } catch (err) {
      logError('Checkout failed', String(err))
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="checkout-form">
      <h2>结账</h2>
      <p>订单总额: {formatPrice(total)}</p>
      <label>
        收货地址:
        <textarea value={address} onChange={e => setAddress(e.target.value)} required />
      </label>
      <button type="submit" disabled={items.length === 0 || isSubmitting}>
        {isSubmitting ? '提交中...' : '提交订单'}
      </button>
    </form>
  )
}