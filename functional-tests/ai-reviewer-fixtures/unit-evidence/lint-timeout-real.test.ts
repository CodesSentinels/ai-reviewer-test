import {describe, expect, test} from '@jest/globals'
import {runCommand, DEFAULT_TOOL_TIMEOUT_MS} from '../src/lint/adapters/exec'

describe('lint tool timeout evidence (FT-203) - real subprocess', () => {
  test('default tool timeout is 60s', () => {
    expect(DEFAULT_TOOL_TIMEOUT_MS).toBe(60_000)
  })

  test('a command exceeding timeoutMs is killed, reported as timedOut, and does not throw', async () => {
    const t0 = Date.now()
    const r = await runCommand({command: 'sleep', args: ['10'], timeoutMs: 300})
    expect(Date.now() - t0).toBeLessThan(5000)
    expect(r.timedOut).toBe(true)
    expect(r.spawnError).toBe(false)
  })

  test('a missing command is reported as spawnError instead of throwing', async () => {
    const r = await runCommand({command: 'definitely-not-a-real-binary-xyz', args: []})
    expect(r.spawnError).toBe(true)
  })
})
