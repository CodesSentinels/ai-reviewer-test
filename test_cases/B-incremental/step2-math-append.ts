// 目标路径: utils/math.ts（第 2 次提交：把本文件内容【追加】到 utils/math.ts 末尾）
// 域 B 第 2 次提交：在 Bot 审完 step1 后，把这些函数【追加】到 utils/math.ts，
// 再 push。预期 Bot 仅评论 divide/power，不重复评论 add/multiply。
export function divide(a: number, b: number): number {
  return a / b // 问题：未检查除零
}

export function power(base: number, exp: number): number {
  let result = 1
  for (let i = 0; i < exp; i++) {
    result *= base // 问题：负指数处理不当
  }
  return result
}
