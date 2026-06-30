// utils/insecure-api.ts
import { createServer } from 'http'

/**
 * 请求处理函数
 * 包含多种典型问题供 AI 审查检测
 */
export function handleRequest(req: any, res: any) {
  // 安全问题 1: SQL 注入
  const userId = req.query.id
  const query = `SELECT * FROM users WHERE id = '${userId}'`

  // 安全问题 2: 未验证的 eval
  const code = req.body.expression
  const result = eval(code)

  // 正确性问题: 忘记 await（async 函数但调用方无法感知错误）
  async function saveData(data: any) {
    fetch('/api/save', { method: 'POST', body: JSON.stringify(data) })
  }

  // 性能问题: 循环内重复创建正则
  function filterItems(items: string[], pattern: string) {
    return items.filter(item => {
      const regex = new RegExp(pattern)
      return regex.test(item)
    })
  }

  saveData({ query, result })
  res.end(JSON.stringify({ result }))
}
