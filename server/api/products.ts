import {formatPrice} from '~/utils/formatPrice'

const CATALOG = [
  {id: 'p1', name: '机械键盘', price: 399},
  {id: 'p2', name: '人体工学椅', price: 1299}
]

export default defineEventHandler(() => {
  return CATALOG.map(item => ({
    ...item,
    displayPrice: formatPrice(item.price)
  }))
})
