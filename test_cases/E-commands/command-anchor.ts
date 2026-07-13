// 目标路径: utils/command-anchor.ts
// 域 E：含问题的代码，先让 Bot 产出行级评论，供 resolve 命令批量解决。
export function unsafeQuery(table: string, id: string): string {
  return `SELECT * FROM ${table} WHERE id = '${id}'` // SQL 注入
}

export function weakToken(): string {
  return Math.random().toString(36).slice(2) // 弱随机
}
