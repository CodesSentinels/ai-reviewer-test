/**
 * OpenAI 调用容错的单测证据：FT-220（429）、FT-221（5xx）、FT-222（超时）、FT-223（空响应）、FT-182（web_search 失败降级）。
 *
 * 为什么不是 jest：ai-reviewer 的 jest 配置把 p-retry 映射成“只调用一次”的 mock（p-retry 是纯 ESM），
 * 在 jest 里测不到真实的重试。这里直接用 Node（>= 22.12，支持 require(esm)）加载 ai-reviewer 编译产物 lib/bot.js，
 * 使用真实的 p-retry 与退避，并用假的 OpenAI 客户端按脚本返回错误或响应。
 *
 * 用法（在 ai-reviewer 仓库根目录；lib/ 是 ESM 产物无法直接 require，先编译一份 CommonJS 副本到仓库内的 .tmp-cjs）：
 *   npx tsc -p tsconfig.json --module commonjs --moduleResolution node --outDir .tmp-cjs
 *   node <本文件路径>
 *   rm -rf .tmp-cjs
 * 或：AI_REVIEWER_DIR=/path/to/ai-reviewer node <本文件路径>
 */
const assert = require('node:assert/strict')
const path = require('node:path')

const root = process.env.AI_REVIEWER_DIR || process.cwd()
process.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY || 'sk-dummy-for-test'
const {Bot} = require(path.join(root, process.env.AI_LIB_DIR || '.tmp-cjs', 'bot.js'))
const OpenAI = require(path.join(root, 'node_modules', 'openai'))
const {APIError} = OpenAI

const OPTIONS = {
  openaiModelTemperature: 0,
  systemMessage: '',
  language: 'zh-CN',
  apiBaseUrl: 'https://api.openai.com/v1',
  openaiTimeoutMS: 1000,
  openaiRetries: 2,
  debug: false
}

function makeBot(opts = {}, webSearch = false) {
  return new Bot(
    {...OPTIONS, ...opts},
    {
      model: 'gpt-5.4-mini',
      tokenLimits: {responseTokens: 1000, knowledgeCutOff: '2025-01'},
      enableWebSearch: webSearch,
      enableShell: false
    }
  )
}

/** 按脚本依次返回：Error 实例 → reject；其余 → resolve */
function scripted(steps) {
  const calls = {n: 0}
  const create = async () => {
    const step = steps[Math.min(calls.n, steps.length - 1)]
    calls.n += 1
    if (step instanceof Error) throw step
    return step
  }
  return {calls, client: {responses: {create}}}
}

const httpError = (status, msg) => APIError.generate(status, {message: msg}, msg, new Headers())
const timeoutError = () => new OpenAI.APIConnectionTimeoutError({message: 'Request timed out.'})
const ok = text => ({id: 'resp_ok', output: [{type: 'message', content: [{type: 'output_text', text}]}]})

const results = []
async function check(ft, name, fn) {
  const t0 = Date.now()
  try {
    await fn()
    results.push({ft, name, ok: true})
    console.log(`PASS ${ft} ${name} (${Date.now() - t0} ms)`)
  } catch (e) {
    results.push({ft, name, ok: false})
    console.log(`FAIL ${ft} ${name}: ${e.message}`)
  }
}

;(async () => {
  // ─── FT-220：429 ───
  await check('FT-220', '连续 2 次 429 后成功：共调用 3 次并返回正文', async () => {
    const s = scripted([httpError(429, 'Rate limit reached'), httpError(429, 'Rate limit reached'), ok('审查结果')])
    const bot = makeBot(); bot.client = s.client
    const [text] = await bot.chat('hello', {})
    assert.equal(s.calls.n, 3)
    assert.equal(text, '审查结果')
  })
  await check('FT-220', '持续 429：重试耗尽（openaiRetries+1=3 次）后返回空文本，不抛异常', async () => {
    const s = scripted([httpError(429, 'Rate limit reached')])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('hello', {})
    assert.equal(s.calls.n, 3)
    assert.equal(res[0], '')
  })

  // ─── FT-221：5xx ───
  await check('FT-221', '500 与 503 后成功：共调用 3 次', async () => {
    const s = scripted([httpError(500, 'Internal server error'), httpError(503, 'Service unavailable'), ok('ok')])
    const bot = makeBot(); bot.client = s.client
    const [text] = await bot.chat('hello', {})
    assert.equal(s.calls.n, 3)
    assert.equal(text, 'ok')
  })
  await check('FT-221', '持续 502：返回空文本，不抛异常', async () => {
    const s = scripted([httpError(502, 'Bad gateway')])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('hello', {})
    assert.equal(s.calls.n, 3)
    assert.equal(res[0], '')
  })
  await check('FT-221', '记录当前行为：401 这类不可重试的客户端错误也被重试（浪费调用，不影响结果）', async () => {
    const s = scripted([httpError(401, 'Incorrect API key')])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('hello', {})
    assert.equal(s.calls.n, 3)
    assert.equal(res[0], '')
  })

  // ─── FT-222：超时 ───
  await check('FT-222', '超时 1 次后成功：共调用 2 次', async () => {
    const s = scripted([timeoutError(), ok('timeout-recovered')])
    const bot = makeBot(); bot.client = s.client
    const [text] = await bot.chat('hello', {})
    assert.equal(s.calls.n, 2)
    assert.equal(text, 'timeout-recovered')
  })
  await check('FT-222', '持续超时：重试耗尽后返回空文本，不抛异常', async () => {
    const s = scripted([timeoutError()])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('hello', {})
    assert.equal(s.calls.n, 3)
    assert.equal(res[0], '')
  })
  await check('FT-222', '客户端按 openai_timeout_ms 设置超时，并关闭 SDK 自带重试（统一由 p-retry 管理）', async () => {
    const bot = makeBot({openaiTimeoutMS: 4321})
    assert.equal(bot.client.timeout, 4321)
    assert.equal(bot.client.maxRetries, 0)
  })

  // ─── FT-223：空响应 ───
  await check('FT-223', 'output 为空数组 → 空文本，不抛异常，只调用 1 次', async () => {
    const s = scripted([{id: 'resp_empty', output: []}])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('hello', {})
    assert.equal(res[0], '')
    assert.deepEqual(res[1], {previousResponseId: 'resp_empty'})
    assert.equal(s.calls.n, 1)
  })
  await check('FT-223', 'output 缺失（null）→ 空文本，不抛异常', async () => {
    const s = scripted([{id: 'resp_null', output: null}])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('hello', {})
    assert.equal(res[0], '')
  })
  await check('FT-223', '消息没有任何 output_text → 空文本', async () => {
    const s = scripted([{id: 'r', output: [{type: 'message', content: []}]}])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('hello', {})
    assert.equal(res[0], '')
  })
  await check('FT-223', '空消息直接返回空，不调用 API', async () => {
    const s = scripted([ok('x')])
    const bot = makeBot(); bot.client = s.client
    const res = await bot.chat('', {})
    assert.equal(res[0], '')
    assert.equal(s.calls.n, 0)
  })

  // ─── FT-182：web_search 失败降级 ───
  await check('FT-182', 'web_search 调用失败但模型仍给出正文：返回正文并记录失败步骤', async () => {
    const s = scripted([
      {
        id: 'resp_ws',
        output: [
          {type: 'web_search_call', id: 'ws_1', status: 'failed', action: {type: 'search', query: 'some api docs'}},
          {type: 'message', content: [{type: 'output_text', text: '没有搜到资料，按已有知识审查'}]}
        ]
      }
    ])
    const bot = makeBot({}, true); bot.client = s.client
    const [text, , steps] = await bot.chat('hello', {})
    assert.equal(text, '没有搜到资料，按已有知识审查')
    assert.equal(steps.length, 1)
    assert.equal(steps[0].type, 'web_search')
    assert.equal(steps[0].status, 'failed')
  })
  await check('FT-182', '开关关闭时响应里的 web_search_call 不会被记录（不对外声称做过搜索）', async () => {
    const s = scripted([
      {
        id: 'resp_ws2',
        output: [
          {type: 'web_search_call', id: 'ws_2', status: 'completed', action: {type: 'search'}},
          {type: 'message', content: [{type: 'output_text', text: 'text'}]}
        ]
      }
    ])
    const bot = makeBot({}, false); bot.client = s.client
    const [text, , steps] = await bot.chat('hello', {})
    assert.equal(text, 'text')
    assert.equal(steps.length, 0)
  })
  await check('FT-182', '带 web_search 的请求本身被 API 拒绝（400）：返回空文本，不抛异常', async () => {
    let seenTools = ''
    const calls = {n: 0}
    const bot = makeBot({}, true)
    bot.client = {
      responses: {
        create: async params => {
          calls.n += 1
          seenTools = JSON.stringify(params.tools)
          throw httpError(400, 'web_search is not supported for this model')
        }
      }
    }
    const res = await bot.chat('hello', {})
    assert.equal(res[0], '')
    assert.ok(seenTools.includes('web_search'))
  })

  const failed = results.filter(r => !r.ok)
  console.log(`\n${results.length - failed.length}/${results.length} passed`)
  process.exit(failed.length === 0 ? 0 : 1)
})()
