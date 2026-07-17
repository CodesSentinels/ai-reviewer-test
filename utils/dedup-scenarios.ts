// 目标路径: utils/dedup-scenarios.ts
// 域 F AI 评论去重：连续同类违规应合并；不同类违规应各自保留。
export function processItems(items: string[]) {
  var item1 = items[0] // no-var（连续 5 行，应合并）
  var item2 = items[1] // no-var
  var item3 = items[2] // no-var
  var item4 = items[3] // no-var
  var item5 = items[4] // no-var

  eval(item1) // no-eval（安全，独立保留）
  console.log(item2) // no-console（风格，独立保留）
  return item3 == item4 ? item5 : null // eqeqeq（正确性，独立保留）
}
