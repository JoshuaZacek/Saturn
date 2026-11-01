<script setup lang="ts">
import type { Component } from 'vue'

defineProps<{
  label: string
  icon: Component
  danger?: boolean
}>()

defineEmits<{
  click: []
}>()
</script>

<template>
  <button class="accountMenuButton" type="button" :class="{ danger }" @click="$emit('click')">
    <component :is="icon" :size="24" />
    <span>{{ label }}</span>
  </button>
</template>

<style scoped>
/* A little smaller than the sidebar's rows: 24px icons and 16px labels. */
.accountMenuButton {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  /* Bleed into the card's padding so the icons line up with the username above. */
  width: calc(100% + 1rem);
  height: 2.375rem;
  margin: 0 -0.5rem;
  padding: 0 0.5rem;
  border: none;
  border-radius: var(--radius-md);
  background: none;
  font-size: var(--text-body);
  text-align: left;
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .accountMenuButton:hover {
    background-color: var(--fill-hover);
  }
}

.accountMenuButton:active {
  background-color: var(--fill-pressed);
}

.danger {
  color: var(--danger);
}
</style>
