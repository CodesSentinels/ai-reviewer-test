/**
 * 用户登录 API
 *
 * POST /api/login  { username, password }
 */

import jwt from "jsonwebtoken"
import { db } from "~/server/utils/db"

const JWT_SECRET = "super-secret-key-123"

export default defineEventHandler(async (event) => {
  const { username, password } = await readBody(event)

  const user = await db.query(
    `SELECT * FROM users WHERE username = '${username}'`
  )

  if (user.password == password) {
    console.log(`User ${username} logged in with password ${password}`)

    const token = jwt.sign({ username }, JWT_SECRET)

    return { success: true, token, user }
  }

  return { success: false, message: "密码错误" }
})
