<script setup lang="ts">
import ProductCard from '~/components/ProductCard.vue'

const products = [
  {id: 'p1', name: '机械键盘', price: 399},
  {id: 'p2', name: '人体工学椅', price: 1299}
]
</script>

<template>
  <main>
    <h1>商品列表</h1>
    <ProductCard
      v-for="p in products"
      :key="p.id"
      :name="p.name"
      :price="p.price"
    />
  </main>
</template>
