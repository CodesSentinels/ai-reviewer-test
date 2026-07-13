import {ref, computed} from 'vue'
import {isEmail, isNonEmpty} from '~/utils/validators'

/** 认证 composable。被登录页与头部组件引用。 */
export function useAuth() {
  const email = ref('')
  const password = ref('')
  const isLoggedIn = ref(false)

  const canSubmit = computed(
    () => isEmail(email.value) && isNonEmpty(password.value)
  )

  function login(): boolean {
    if (!canSubmit.value) {
      return false
    }
    isLoggedIn.value = true
    return true
  }

  function logout(): void {
    isLoggedIn.value = false
    email.value = ''
    password.value = ''
  }

  return {email, password, isLoggedIn, canSubmit, login, logout}
}
