/**
 * ProductCard.tsx — 商品卡片组件
 *
 * 导入 calculator.ts 的 formatPrice
 * 导入 formatter.ts 的 truncateText
 *
 * 不导入 calculateTotal 或 TAX_RATE，Case A/B 时不会出现在引用中
 */
import React from 'react'
import { formatPrice } from '../utils/calculator'
import { truncateText } from '../utils/formatter'
import type { CartItem } from '../utils/calculator'

interface ProductCardProps {
  product: { id: string; name: string; price: number; description: string }
  onAddToCart: (item: CartItem) => void
}

export const ProductCard: React.FC<ProductCardProps> = ({ product, onAddToCart }) => {
  const handleAdd = () => {
    onAddToCart({
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: 1,
    })
  }

  return (
    <div className="product-card">
      <h3>{product.name}</h3>
      <p>{truncateText(product.description, 80)}</p>
      <p className="price">{formatPrice(product.price)}</p>
      <button onClick={handleAdd}>加入购物车</button>
    </div>
  )
}