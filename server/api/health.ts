/** 健康检查端点。基线中保持安全、无缺陷。 */
export default defineEventHandler(() => {
  return {status: 'ok', ts: Date.now()}
})
