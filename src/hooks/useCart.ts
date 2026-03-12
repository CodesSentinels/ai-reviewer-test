/**
 * useCart.ts — 购物车 Hook
 *
 * 导入 calculator.ts 的 calculateTotal, calculateTotalWithTax, TAX_RATE
 * 导入 logger.ts 的 logInfo
 *
 * Case A 时：calculateTotal 的引用会在此文件被检测到
 * Case B 时：TAX_RATE 的引用会在此文件被检测到
 * Case G 时：logInfo 的引用会在此文件被检测到
 */
import { useState, useCallback, useMemo } from 'react'
import { calculateTotal, calculateTotalWithTax, TAX_RATE } from '../utils/calculator'
import { logInfo } from '../utils/logger'
import type { CartItem, Coupon } from '../utils/calculator'

export function useCart() {
  const [items, setItems] = useState<CartItem[]>([])
  const [coupon, setCoupon] = useState<Coupon | null>(null)

  const addItem = useCallback((item: CartItem) => {
    logInfo('Adding item to cart', item.name)
    setItems(prev => {
      const existing = prev.find(i => i.id === item.id)
      if (existing) {
        return prev.map(i =>
          i.id === item.id ? { ...i, quantity: i.quantity + item.quantity } : i
        )
      }
      return [...prev, item]
    })
  }, [])

  const removeItem = useCallback((itemId: string) => {
    logInfo('Removing item from cart', itemId)
    setItems(prev => prev.filter(i => i.id !== itemId))
  }, [])

  const subtotal = useMemo(() => calculateTotal(items), [items])
  const total = useMemo(() => calculateTotalWithTax(items), [items])
  const taxAmount = useMemo(() => subtotal * TAX_RATE, [subtotal])

  return { items, coupon, subtotal, taxAmount, total, addItem, removeItem, setCoupon }
}