<template>
  <div class="search-page">
    <input
      v-model="query"
      type="text"
      placeholder="搜索..."
      class="search-input"
    />

    <div v-if="loading" class="loading">搜索中...</div>

    <div v-if="error" class="error">{{ error }}</div>

    <ul v-if="results.length" class="results-list">
      <!-- Bug 7: 直接使用数组下标作为 key，列表重排时会触发错误的组件复用 -->
      <li v-for="(item, index) in results" :key="index">
        {{ item }}
      </li>
    </ul>

    <div v-if="!loading && !results.length && query" class="empty">
      没有找到相关结果
    </div>
  </div>
</template>

<script setup lang="ts">
import { useSearch } from "~/composables/useSearch"

const { query, results, loading, error, initFromUrl } = useSearch()

// Bug 8: 在 SSR 环境下调用 window.location，服务端渲染时会抛出 ReferenceError
// 修改点: 应使用 onMounted 包裹或使用 useRoute() 替代 window.location
initFromUrl()
</script>

<style scoped>
.search-page {
  max-width: 600px;
  margin: 0 auto;
  padding: 2rem;
}

.search-input {
  width: 100%;
  padding: 0.5rem 1rem;
  font-size: 1rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.results-list {
  margin-top: 1rem;
  list-style: none;
  padding: 0;
}

.loading,
.error,
.empty {
  margin-top: 1rem;
  color: #666;
}

.error {
  color: #e53e3e;
}
</style>
