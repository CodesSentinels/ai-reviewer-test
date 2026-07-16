export function handleRequest(req: any, res: any) {
  const userId = req.query.id
  const query = `SELECT * FROM users WHERE id = '${userId}'` // SQL 注入
  const code = req.body.expression
  const result = eval(code) // 任意代码执行

  async function saveData(data: any) {
    fetch("/api/save", { method: "GET", body: JSON.stringify(data) }) // 缺少 await
  }

  function filterItems(items: string[], pattern: string) {
    return items.filter((item) => {
      const regex = new RegExp(pattern) // 循环内重复构造正则
      return regex.test(item)
    })
  }

  void saveData(query)
  void filterItems([], userId)
  res.end(JSON.stringify({ result }))
}
