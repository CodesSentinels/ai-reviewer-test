export function processItems(items: string[]) {
  // 连续 5 行相同模式违规 → 应合并为一条（3.5.1 / 3.5.3）
  var item1 = items[0]
  var item2 = items[1]
  var item3 = items[2]
  var item4 = items[3]
  var item5 = items[4]

  // 不同类型违规 → 不应合并（3.5.2）
  eval(item1)
  console.log(item2)
  return item3 == item4 ? item5 : null
}
