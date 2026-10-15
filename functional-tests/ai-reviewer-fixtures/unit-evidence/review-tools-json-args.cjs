/**
 * FT-224（非法 JSON 安全处理）、FT-225（Markdown 包裹输出正确处理）的单测证据。
 *
 * 为什么用“工具调用参数”：产品的审查输出本身不是 JSON（行号范围 + Markdown 文本），
 * 但模型发起只读代码探查工具调用时，`arguments` 是模型生成的 JSON 字符串（src/review-tools.ts 的
 * executeReviewTool 用 JSON.parse 解析）。这是产品里唯一一处“解析模型生成的 JSON”的地方，
 * 非法 JSON、被 Markdown 围栏包住的 JSON 都会出现在这里。
 *
 * 用法（在 ai-reviewer 仓库根目录；lib/ 是 ESM，先编译一份 CommonJS 副本）：
 *   npx tsc -p tsconfig.json --module commonjs --moduleResolution node --outDir .tmp-cjs
 *   node <本文件路径>
 *   rm -rf .tmp-cjs
 */
const assert = require('node:assert/strict')
const path = require('node:path')
const root = process.env.AI_REVIEWER_DIR || process.cwd()
const {executeReviewTool} = require(path.join(root, process.env.AI_LIB_DIR || '.tmp-cjs', 'review-tools.js'))

const results = []
async function check(ft, name, fn) {
  try {
    await fn()
    results.push(true)
    console.log(`PASS ${ft} ${name}`)
  } catch (e) {
    results.push(false)
    console.log(`FAIL ${ft} ${name}: ${e.message}`)
  }
}

async function run(argsJson) {
  // 任何输入都不能抛异常；错误以 error 文本返回给模型
  const r = await executeReviewTool('read_file', argsJson)
  return r
}

;(async () => {
  await check('FT-224', '截断的 JSON → 返回“arguments are not valid JSON”，不抛异常', async () => {
    const r = await run('{"path":"package.json"')
    assert.match(String(r.step.error), /not valid JSON/)
  })
  await check('FT-224', '纯文本（不是 JSON）→ 同上', async () => {
    const r = await run('read package.json please')
    assert.match(String(r.step.error), /not valid JSON/)
  })
  await check('FT-224', '空字符串 → 按空对象处理，返回 invalid path 错误，不抛异常', async () => {
    const r = await run('')
    assert.match(String(r.step.error), /invalid path/)
  })
  await check('FT-224', 'JSON 数组 / null / 数字（合法 JSON 但不是对象）→ invalid path，不抛异常', async () => {
    for (const v of ['[1,2,3]', 'null', '42']) {
      const r = await run(v)
      assert.match(String(r.step.error), /invalid path/, v)
    }
  })
  await check('FT-224', '类型错误（path 为数字）→ invalid path，不抛异常', async () => {
    const r = await run('{"path":123,"start_line":"x"}')
    assert.match(String(r.step.error), /invalid path/)
  })
  await check('FT-224', '路径穿越（../../etc/passwd）→ invalid path，没有读取任何文件', async () => {
    const r = await run('{"path":"../../etc/passwd"}')
    assert.match(String(r.step.error), /invalid path/)
  })
  await check('FT-225', '被 Markdown 围栏包住的 JSON → 不解包，按非法 JSON 安全拒绝并把错误返回给模型，不抛异常', async () => {
    const r = await run('```json\n{"path":"package.json"}\n```')
    assert.match(String(r.step.error), /not valid JSON/)
  })
  await check('FT-225', '未知工具名 → 返回 unknown tool 错误，不抛异常', async () => {
    const r = await executeReviewTool('definitely_not_a_tool', '{}')
    assert.match(String(r.step.error), /unknown tool/)
  })

  const failed = results.filter(x => !x).length
  console.log(`\n${results.length - failed}/${results.length} passed`)
  process.exit(failed === 0 ? 0 : 1)
})()
