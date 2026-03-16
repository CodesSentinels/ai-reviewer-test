/**
 * permissionService.ts — 权限服务
 *
 * 与 authService.ts 形成循环引用关系：
 * permissionService → authService（获取当前用户）
 * authService → permissionService（检查权限）
 *
 * 测试 Case N: 循环引用保护
 * → 当 authService 中 getCurrentUser 被修改时，permissionService 是直接依赖方
 * → 当 permissionService 中 checkPermission 被修改时，authService 是直接依赖方
 * → 两者不应互相递归追踪
 */
import { getCurrentUser } from './authService'
import { logInfo, logWarn } from '../utils/logger'
import type { User } from './authService'

/** 权限规则定义 */
const PERMISSION_MAP: Record<string, string[]> = {
  admin: ['read', 'write', 'delete', 'manage'],
  editor: ['read', 'write'],
  viewer: ['read'],
}

/** 检查指定用户是否拥有某项权限（供 authService 调用） */
export function checkPermission(user: User, action: string): boolean {
  const allowed = PERMISSION_MAP[user.role] ?? []
  const hasPermission = allowed.includes(action)

  if (!hasPermission) {
    logWarn('Permission denied', `user=${user.id}, action=${action}, role=${user.role}`)
  }

  return hasPermission
}

/** 获取当前用户的所有权限 */
export function getCurrentPermissions(): string[] {
  const user = getCurrentUser()
  if (!user) {
    logWarn('No current user for permission query')
    return []
  }

  const permissions = PERMISSION_MAP[user.role] ?? []
  logInfo('Permissions queried', `user=${user.id}, permissions=[${permissions.join(',')}]`)
  return permissions
}

/** 要求指定权限，无权限时抛出异常 */
export function requirePermission(action: string): void {
  const user = getCurrentUser()
  if (!user) {
    throw new Error('未登录')
  }
  if (!checkPermission(user, action)) {
    throw new Error(`权限不足: ${action}`)
  }
}
