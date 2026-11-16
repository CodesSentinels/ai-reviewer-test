<script setup lang="ts">
import { ref, onMounted, onUnmounted } from "vue"

const stats = ref<{ users: number; orders: number } | null>(null)
let pollTimer: ReturnType<typeof setInterval> | null = null

async function fetchStats() {
  stats.value = await $fetch("/api/dashboard/stats")
}

onMounted(() => {
  fetchStats()
  pollTimer = setInterval(fetchStats, 3000)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})
</script>

<template>
  <div v-if="stats">用户 {{ stats.users }} · 订单 {{ stats.orders }}</div>
</template>
