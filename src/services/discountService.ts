/**
 * discountService.ts — 折扣计算服务
 *
 * 使用 **符号别名** 导入 calculator 中的函数
 *
 * 测试 Case J: import { calculateTotal as calcTotal } → 验证别名引用能被追踪
 * 当 calculateTotal 被修改时，本文件中 calcTotal() 的调用应被检测为引用
 */
import { calculateTotal as calcTotal, TAX_RATE as taxRate } from '../utils/calculator'
import { logInfo as log } from '../utils/logger'
import type { CartItem, Coupon } from '../utils/calculator'

export interface DiscountResult {
  originalTotal: number
  discountAmount: number
  finalTotal: number
  taxAmount: number
}

/** 使用别名 calcTotal 调用原始函数 calculateTotal */
export function applyDiscount(items: CartItem[], coupon: Coupon): DiscountResult {
  const originalTotal = calcTotal(items)
  const discountAmount = originalTotal * coupon.discount
  const finalTotal = originalTotal - discountAmount
  const taxAmount = finalTotal * taxRate

  log('Discount applied', `code=${coupon.code}, saved=${discountAmount}`)

  return {
    originalTotal,
    discountAmount,
    finalTotal,
    taxAmount,
  }
}

/** 比较多个优惠券，选出最优 */
export function findBestCoupon(items: CartItem[], coupons: Coupon[]): Coupon | null {
  if (coupons.length === 0) return null

  const total = calcTotal(items)
  let bestCoupon: Coupon | null = null
  let bestDiscount = 0

  for (const coupon of coupons) {
    const discount = total * coupon.discount
    if (discount > bestDiscount) {
      bestDiscount = discount
      bestCoupon = coupon
    }
  }

  log('Best coupon found', `code=${bestCoupon?.code}, discount=${bestDiscount}`)
  return bestCoupon
}
