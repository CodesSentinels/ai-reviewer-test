import { experimental_useOptimistic } from 'react'
import { styleText } from 'node:util'

// 使用实验性/新 API — 正常情况下会触发 web_search
export function ExperimentalComponent() {
  const [optimistic, setOptimistic] = experimental_useOptimistic(null)
  return { optimistic }
}

// Node.js 22 API — 正常情况下会触发 web_search
export function colorOutput(msg: string) {
  console.log(styleText('green', msg))
}

// 依赖版本问题 — 正常情况下会触发 shell
import Fastify from 'fastify'
const app = Fastify()
app.decorateRequest('user', null)
