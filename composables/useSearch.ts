/**
 * 搜索 composable
 *
 * 依赖 utils/event-utils 中的 debounce 和 parseQueryString
 * Analysis chain: event-utils.debounce → useSearch → search.vue
 */
import { debounce, parseQueryString } from "~/utils/event-utils"

export function useSearch(initialQuery = "") {
  const query = ref(initialQuery)
  const results = ref<unknown[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchResults(q: string) {
    if (!q.trim()) {
      results.value = []
      return
    }
    loading.value = true
    error.value = null
    try {
      // 模拟 API 请求
      const res = await $fetch<{ items: unknown[] }>(`/api/search?q=${encodeURIComponent(q)}`)
      results.value = res.items
    } catch (e) {
      error.value = (e as Error).message
    } finally {
      loading.value = false
    }
  }

  // Bug 5: 使用了有缺陷的 debounce（未 clearTimeout），快速输入时仍会多次请求
  const debouncedFetch = debounce(fetchResults, 300)

  watch(query, (val) => {
    debouncedFetch(val)
  })

  // Bug 6: 缺少 onUnmounted 清理，组件销毁后 debouncedFetch 仍可能执行并修改 results
  // 修改点: 应在 onUnmounted 中取消 pending 的 debounce 调用

  function initFromUrl() {
    const params = parseQueryString(window.location.search)
    if (params.q) {
      query.value = params.q
    }
  }

  return { query, results, loading, error, initFromUrl }
}
