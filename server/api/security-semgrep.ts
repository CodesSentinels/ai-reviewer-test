// 目标路径: server/api/insecure-endpoints.ts
// 域 G（G7 Semgrep）：需 workflow 设 enable_semgrep: true。
// 预期 Bot 评论引用 Semgrep 规则 ID（注入 / XSS 等）。
import express from 'express'
import {execSync} from 'child_process'

const app = express()

// semgrep: express xss
app.get('/profile', (req, res) => {
  res.send(`<h1>Welcome ${req.query.name}</h1>`)
})

// semgrep: dangerous-exec
app.post('/run', (req, res) => {
  const output = execSync(req.body.command)
  res.json({output: output.toString()})
})
