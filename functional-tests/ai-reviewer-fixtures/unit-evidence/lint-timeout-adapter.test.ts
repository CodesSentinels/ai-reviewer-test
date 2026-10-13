import {describe, expect, jest, test, beforeEach} from '@jest/globals'
import {mkdtempSync} from 'fs'
import {tmpdir} from 'os'
import * as path from 'path'

jest.mock('@actions/core', () => ({info: jest.fn(), warning: jest.fn()}))
jest.mock('../src/lint/tool-installer', () => ({
  ensureToolInstalled: jest.fn(async () => ({ok: true, binPath: '/tmp/x/biome'}))
}))
interface Fake {
  exitCode: number | null
  timedOut: boolean
  stdout: string
  stderr: string
  spawnError: boolean
}
const runCommandMock = jest.fn<(o: unknown) => Promise<Fake>>()
jest.mock('../src/lint/adapters/exec', () => ({
  runCommand: (o: unknown) => runCommandMock(o),
  extractVersion: (s: string) => s.match(/v?(\d+\.\d+\.\d+)/)?.[1] ?? '',
  parseJsonSafe: jest.fn()
}))
import {BiomeAdapter} from '../src/lint/adapters/biome'

beforeEach(() => {
  runCommandMock.mockReset()
})

describe('adapter degrades safely when the tool times out (FT-203)', () => {
  test('biome scan timing out yields no findings and does not throw', async () => {
    const root = mkdtempSync(path.join(tmpdir(), 'biome-timeout-'))
    runCommandMock.mockResolvedValueOnce({exitCode: 0, timedOut: false, stdout: 'Version: 2.4.14\n', stderr: '', spawnError: false})
    runCommandMock.mockResolvedValueOnce({exitCode: null, timedOut: true, stdout: '', stderr: '', spawnError: false})
    const adapter = new BiomeAdapter()
    await adapter.detect(root)
    const findings = await adapter.scan(['src/foo.ts'], root)
    expect(findings).toEqual([])
  })
})
