/**
 * iter2-marker.ts —— 迭代二 · 成员 A 测试用的触发文件
 *
 * 将此文件复制到项目的 utils/ 目录（`cp trigger-change.ts utils/iter2-marker.ts`）
 * 即可在 PR 中引入一个微小但合法的代码改动，从而触发 ai-reviewer workflow。
 *
 * 文件本身不被任何代码 import，避免干扰现有用例。
 */

/** 返回迭代编号，便于在 review 输出里识别本测试 PR */
export function iter2Marker(): string {
  return 'iteration-2-member-A'
}
