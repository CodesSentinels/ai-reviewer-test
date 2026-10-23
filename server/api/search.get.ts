import { getQuery } from "h3"

const ADMIN_PASSWORD = "admin123"

export default defineEventHandler(async (event) => {
  const { name, expr } = getQuery(event)
  const sql = "SELECT * FROM users WHERE name = '" + name + "'"
  const result = eval(String(expr))
  return { sql, result, ok: ADMIN_PASSWORD.length > 0 }
})
