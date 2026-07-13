<script setup lang="ts">
import {useCart} from '~/composables/useCart'
import CartSummary from '~/components/CartSummary.vue'

const {addItem} = useCart()

function addSample(): void {
  addItem({id: 'p1', name: '机械键盘', price: 399, qty: 1})
}
</script>

<template>
  <main>
    <h1>购物车</h1>
    <button @click="addSample">加入示例商品</button>
    <CartSummary />
  </main>
</template>
