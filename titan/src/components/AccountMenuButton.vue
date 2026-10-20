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
.accountMenuButton {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  /* Bleed into the card's padding so the icons line up with the username above. */
  width: calc(100% + 1rem);
  margin: 0 -0.5rem;
  padding: 0.4rem 0.5rem;
  border: none;
  border-radius: 8px;
  background: none;
  font-size: 1.05rem;
  text-align: left;
  cursor: pointer;
}

.accountMenuButton svg {
  /* Phosphor glyphs sit ~2.5px inside their box; pull them back to the text edge. */
  margin-left: -2.5px;
}

.accountMenuButton:hover {
  background-color: var(--bg-2);
}

.danger span {
  color: var(--text-error);
}

/* The global `* { color }` rule reaches the icon's <path>, so `currentColor`
   there wouldn't be red; set the fill on the path itself. */
.danger :deep(path) {
  fill: var(--text-error);
}
</style>
