<script setup lang="ts">
import { computed } from "vue";
import { formatOrder } from "../shared/formatter";
import type { Order } from "../shared/types";

const props = defineProps<{ order: Order }>();
const label = computed(() => formatOrder(props.order));
</script>

<template>
  <div class="order-card">{{ label }}</div>
</template>
