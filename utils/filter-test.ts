// utils/filter-test.ts
// generated: 2026-07-01 15:17:18
// 这是唯一应该被审查的文件（.ts 在 path_filters 范围内）

export function processUserData(data: any) {
  // 问题: 直接使用 any 类型
  // 问题: 未做输入校验
  return JSON.parse(data)
}

export function buildUrl(base: string, path: string) {
  // 问题: 字符串拼接而非 URL 构造器
  return base + '/' + path
}
