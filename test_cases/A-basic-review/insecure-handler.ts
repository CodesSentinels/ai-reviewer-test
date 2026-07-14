// 目标路径: server/api/request-handler.ts（把本文件拷到基线的此路径后提交）
// 域 A 测试文件：故意植入多类问题，触发四阶段审查 + 行级评论。
// 预期 Bot 指出：SQL 注入 / eval / 未 await / 循环内建正则。
export function handleRequest(req: any, res: any) {
  const userId = req.query.id
  const query = `SELECT * FROM users WHERE id = '${userId}'` // SQL 注入
  const code = req.body.expression
  const result = eval(code) // 任意代码执行

  async function saveData(data: any) {
    fetch('/api/save', {method: 'POST', body: JSON.stringify(data)}) // 缺少 await
  }

  function filterItems(items: string[], pattern: string) {
    return items.filter(item => {
      const regex = new RegExp(pattern) // 循环内重复构造正则
      return regex.test(item)
    })
  }

  void saveData(query)
  void filterItems([], userId)
  res.end(JSON.stringify({result}))
}
