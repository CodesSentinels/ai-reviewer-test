/**
 * 使用特定版本依赖 API — 期望触发 Bot 的 shell 工具
 * （如 npm info / cat package.json 检查版本兼容性）
 */
import Fastify from 'fastify'

const app = Fastify({ logger: true })

// Fastify v5 breaking change: 路由选项语法变更
app.get('/api/users', {
  schema: {
    response: {
      200: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            name: { type: 'string' }
          }
        }
      }
    }
  }
}, async (request, reply) => {
  // 使用 reply.code() 替代 reply.status()（v5 变更）
  return reply.code(200).send([{ id: 1, name: 'Alice' }])
})

// 使用 deprecated 的 decorateRequest 语法
app.decorateRequest('user', null)

app.listen({ port: 3000 })
