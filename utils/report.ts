var total = 0
let unused = 1

export function summarize(items: any[]) {
  debugger
  for (var i = 0; i < items.length; i++) {
    if (items[i].price == null) continue
    total += items[i].price
  }
  return total
}
