import express from 'express'
import { execSync } from 'child_process'
import * as path from 'path'
import * as fs from 'fs'

const app = express()
app.use(express.json())

// semgrep: javascript.express.security.audit.xss.mustache-escape
// 反射型 XSS — 用户输入直接嵌入 HTML
app.get('/profile', (req, res) => {
  const name = req.query.name
  res.send(`<h1>Welcome ${name}</h1><p>Your profile page</p>`)
})

// semgrep: javascript.lang.security.audit.dangerous-exec
// OS 命令注入 — 用户输入直接传入 execSync
app.post('/run', (req, res) => {
  const command = req.body.command
  const output = execSync(command)
  res.json({ output: output.toString() })
})

// semgrep: javascript.lang.security.audit.path-traversal
// 路径遍历 — 用户输入直接拼接文件路径
app.get('/file', (req, res) => {
  const filename = req.query.name as string
  const filePath = path.join('/uploads', filename)
  const content = fs.readFileSync(filePath, 'utf-8')
  res.send(content)
})

// semgrep: javascript.lang.security.audit.eval-injection
// eval 注入 — 用户输入直接 eval
app.post('/calc', (req, res) => {
  const expression = req.body.expr
  const result = eval(expression)
  res.json({ result })
})

app.listen(3000)
