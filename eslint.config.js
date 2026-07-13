// 扁平配置（ESLint 9）。ai-reviewer 的 ESLint 适配器会读取此文件；
// 缺失时适配器降级为 unavailable。
export default [
  {
    files: ['**/*.ts', '**/*.vue'],
    rules: {
      'no-unused-vars': 'warn',
      'no-undef': 'error',
      'no-var': 'error',
      eqeqeq: 'warn',
      'no-eval': 'error',
      'no-console': 'warn'
    }
  }
]
