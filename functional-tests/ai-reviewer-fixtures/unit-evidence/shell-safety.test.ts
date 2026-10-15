import {describe, test, expect, afterEach} from '@jest/globals'
import {Bot} from '../src/bot'

const mk = (): any => {
  process.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY ?? 'sk-dummy-for-test'
  return new Bot(
    {openaiModelTemperature: 0, systemMessage: ''} as any,
    {model: 'gpt-5.4-mini', tokenLimits: {responseTokens: 1000}, enableWebSearch: false, enableShell: true} as any
  )
}

const call = (commands: string[], extra: Record<string, unknown> = {}) => ({
  call_id: 'c1',
  action: {commands, ...extra}
})

describe('local shell safety evidence (FT-185/186)', () => {
  const OLD = {...process.env}
  afterEach(() => {
    process.env = {...OLD}
  })

  test('timeout: command exceeding timeout_ms is killed and reported as timeout', async () => {
    const bot = mk()
    const t0 = Date.now()
    const out = await bot.runLocalShellCall(call(['sleep 10'], {timeout_ms: 500}))
    expect(Date.now() - t0).toBeLessThan(5000)
    expect(out.output[0].outcome).toEqual({type: 'timeout'})
  })

  test('output limit: default 4096 chars, truncated with marker', async () => {
    const bot = mk()
    const out = await bot.runLocalShellCall(call(["head -c 20000 /dev/zero | tr '\\0' 'a'"]))
    const s = out.output[0].stdout as string
    expect(s.length).toBeLessThanOrEqual(4096 + 40)
    expect(s).toContain('(truncated)')
  })

  test('explicit max_output_length is honoured', async () => {
    const bot = mk()
    const out = await bot.runLocalShellCall(call(["head -c 5000 /dev/zero | tr '\\0' 'b'"], {max_output_length: 100}))
    expect((out.output[0].stdout as string).length).toBeLessThanOrEqual(140)
  })

  test('sensitive env keys are removed from the shell environment', async () => {
    process.env.OPENAI_API_KEY = 'sk-test-should-not-leak'
    process.env.GITHUB_TOKEN = 'ghs_test_should_not_leak'
    process.env.FAKE_OTHER_SECRET = 'other-secret-value'
    const bot = mk()
    const out = await bot.runLocalShellCall(call(['echo "F=[$FAKE_OTHER_SECRET] O=[$OPENAI_API_KEY] G=[$GITHUB_TOKEN]"']))
    const s = out.output[0].stdout as string
    expect(s).not.toContain('sk-test-should-not-leak')
    expect(s).not.toContain('ghs_test_should_not_leak')
    // 记录：未在白名单中的其他变量仍然可见（输出不做脱敏）
    expect(s).toContain('F=[other-secret-value]')
    expect(s).toContain('O=[]')
    expect(s).toContain('G=[]')
  })
})

describe('shell output is not redacted (FT-186)', () => {
  test('token-shaped strings in command output are passed through unchanged', async () => {
    process.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY ?? 'sk-dummy-for-test'
    const bot: any = new Bot(
      {openaiModelTemperature: 0, systemMessage: ''} as any,
      {model: 'gpt-5.4-mini', tokenLimits: {responseTokens: 1000}, enableWebSearch: false, enableShell: true} as any
    )
    const out = await bot.runLocalShellCall({
      call_id: 'c2',
      action: {commands: ["echo 'key=sk-proj-FAKEFAKEFAKEFAKEFAKE1234 gh=ghp_FAKEFAKEFAKEFAKEFAKEFAKEFAKE123456'"]}
    })
    const s = out.output[0].stdout as string
    expect(s).toContain('sk-proj-FAKEFAKEFAKEFAKEFAKE1234')
    expect(s).toContain('ghp_FAKEFAKEFAKEFAKEFAKEFAKEFAKE123456')
  })
})
