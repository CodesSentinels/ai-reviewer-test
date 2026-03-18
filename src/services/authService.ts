/**
 * authService.ts — 认证服务
 *
 * 与 permissionService.ts 形成循环引用关系：
 * authService → permissionService（检查权限）
 * permissionService → authService（获取当前用户）
 *
 * 测试 Case N: 循环引用保护
 * → 两个文件互相 import，依赖图中不应出现无限循环
 * → step 6 跳过 dep.file === modifiedFile 的条目
 */
import { logError, logInfo, logWarn } from "../utils/logger";
import { checkPermission } from "./permissionService";

export interface User {
  id: string;
  name: string;
  role: "admin" | "editor" | "viewer";
}

let currentUser: User | null = null;

/** 获取当前登录用户（供 permissionService 调用） */
// export function getCurrentUser(): User | null {
//   return currentUser
// }

// Case M：循环引用 → 保护机制
export function getCurrentUser(): User | null {
  if (!currentUser) {
    logWarn("getCurrentUser called but no user is logged in");
  }
  return currentUser;
}

/** 登录 */
export async function login(userId: string, password: string): Promise<User> {
  logInfo("Login attempt", `userId=${userId}`);

  // 模拟认证逻辑
  const user: User = {
    id: userId,
    name: `User ${userId}`,
    role: "editor",
  };

  currentUser = user;
  logInfo("Login successful", `userId=${userId}, role=${user.role}`);
  return user;
}

/** 检查当前用户是否有指定操作的权限 */
export function canPerformAction(action: string): boolean {
  if (!currentUser) {
    logError("Permission check failed", "no current user");
    return false;
  }
  return checkPermission(currentUser, action);
}

/** 登出 */
export function logout(): void {
  const userId = currentUser?.id ?? "unknown";
  currentUser = null;
  logInfo("Logout", `userId=${userId}`);
}
