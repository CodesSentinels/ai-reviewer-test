/** 极简类型化 API 客户端封装，被 composables 引用。 */
export interface ApiResult<T> {
  ok: boolean
  data?: T
  error?: string
}

export async function getJson<T>(url: string): Promise<ApiResult<T>> {
  try {
    const response = await fetch(url, {headers: {Accept: 'application/json'}})
    if (!response.ok) {
      return {ok: false, error: `HTTP ${response.status}`}
    }
    const data = (await response.json()) as T
    return {ok: true, data}
  } catch (err) {
    return {ok: false, error: err instanceof Error ? err.message : 'unknown'}
  }
}
