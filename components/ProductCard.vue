<script setup lang="ts">
import { computed } from "vue"
import { formatPrice } from "~/utils/formatPrice"

const props = defineProps<{
  name: string
  price: string
}>()

const displayPrice = computed(() => formatPrice(props.price))
</script>

<template>
  <div class="product-card">
    <h3>{{ name }}</h3>
    <span class="price">{{ displayPrice }}</span>
  </div>
</template>
