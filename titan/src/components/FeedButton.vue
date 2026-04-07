<script setup lang="ts">
import type { Component } from 'vue'

defineProps<{
  label: string
  icon: Component
  active?: boolean
  iconSize?: number
}>()

defineEmits<{
  click: []
}>()
</script>

<template>
  <button class="feedButton" type="button" :class="{ active }" @click="$emit('click')">
    <component :is="icon" :filled="active" :size="iconSize ?? 30" />
    <span>{{ label }}</span>
  </button>
</template>

<style scoped>
.feedButton {
  display: flex;
  align-items: center;
  width: 100%;
  border: none;
  background: none;
  text-align: left;
  cursor: pointer;
  border-radius: 10px;
  font-size: 1.1rem;
  height: 2.75rem;
  gap: 0.25rem;
  padding-left: 0.5rem;
}

.feedButton.active {
  background-color: var(--bg-2);
  font-weight: bold;
}
</style>
