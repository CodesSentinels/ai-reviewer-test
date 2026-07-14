// 目标路径: utils/diagnostic.ts
// 域 H：含依赖/版本相关问题的代码，诱导模型请求执行 shell 辅助分析。
// 预期 Analysis chain 中出现 shell 步骤（enable_shell: true 时）。
import {exec} from 'child_process'

export function runDiagnostic(userInput: string): Promise<string> {
  return new Promise((resolve, reject) => {
    // 危险：用户输入直接拼接进 shell 命令（命令注入）
    exec(`echo ${userInput} | grep -c "ok"`, (error, stdout) => {
      if (error) reject(error)
      else resolve(stdout.trim())
    })
  })
}
