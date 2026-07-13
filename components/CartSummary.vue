<script setup lang="ts">
import {useCart} from '~/composables/useCart'

const {items, formattedTotal, removeItem} = useCart()
</script>

<template>
  <div class="cart-summary">
    <ul>
      <li v-for="item in items" :key="item.id">
        {{ item.name }} × {{ item.qty }}
        <button @click="removeItem(item.id)">移除</button>
      </li>
    </ul>
    <p class="total">合计：{{ formattedTotal }}</p>
  </div>
</template>
