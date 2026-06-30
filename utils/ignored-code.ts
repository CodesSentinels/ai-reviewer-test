// utils/ignored-code.ts
// 这段代码有明显问题，但 PR 设置了 ignore，Bot 不应评论
export function badFunction(input: any) {
  const query = `DELETE FROM users WHERE id = '${input}'`
  eval(query)
  return query
}
