/**
 * 认证 composable
 *
 * 测试场景 1: 被 components/CartSummary.vue 显式导入
 * 测试场景 8: 使用 base-layer/utils/logger.ts 的 logInfo
 */
import { useUserStore } from "~/stores/userStore"
import { logInfo } from "~/base-layer/utils/logger"

export function useAuth(options?: { redirectOnLogout?: boolean }) {
  const userStore = useUserStore()
  const isLoggedIn = computed(() => !!userStore.currentUser)

  async function login(email: string, password: string) {
    logInfo("login attempt", { email })
    await userStore.setUser({ email, name: email.split("@")[0] })
  }

  async function logout() {
    logInfo("logout")
    userStore.clearUser()
  }

  return { isLoggedIn, login, logout }
}
