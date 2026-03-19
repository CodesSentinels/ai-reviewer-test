/**
 * 主题 composable（来自 base-layer）
 *
 * 测试场景 6: 被 layouts/default.vue 和 components/ProductCard.vue auto-import 使用
 */
export function useTheme() {
  const isDark = useState('theme-dark', () => false)

  function toggleTheme() {
    isDark.value = !isDark.value
  }

  return { isDark, toggleTheme }
}
