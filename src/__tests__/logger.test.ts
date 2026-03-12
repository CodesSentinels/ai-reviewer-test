/**
 * logger.test.ts — logger 单元测试
 *
 * 测试 Case E: 测试文件被跳过
 */
import { log, logInfo, logError, setLogLevel } from '../utils/logger'

describe('logger', () => {
  it('should log info messages', () => {
    const spy = jest.spyOn(console, 'info').mockImplementation()
    logInfo('test message')
    expect(spy).toHaveBeenCalled()
    spy.mockRestore()
  })

  it('should log error messages', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation()
    logError('error message')
    expect(spy).toHaveBeenCalled()
    spy.mockRestore()
  })

  it('should respect log level', () => {
    const spy = jest.spyOn(console, 'debug').mockImplementation()
    setLogLevel('error')
    log('debug', 'should not appear')
    expect(spy).not.toHaveBeenCalled()
    setLogLevel('info')
    spy.mockRestore()
  })
})