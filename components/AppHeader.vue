<script setup lang="ts">
import {useAuth} from '~/composables/useAuth'

const {isLoggedIn, logout} = useAuth()
</script>

<template>
  <header class="app-header">
    <nav>
      <NuxtLink to="/">首页</NuxtLink>
      <NuxtLink to="/cart">购物车</NuxtLink>
    </nav>
    <button v-if="isLoggedIn" @click="logout">退出登录</button>
  </header>
</template>
