<script setup lang="ts">
import type { Component } from 'vue'

defineProps<{
  label: string
  icon: Component
  active?: boolean
  danger?: boolean
}>()

defineEmits<{
  click: []
}>()
</script>

<template>
  <button
    class="accountMenuButton"
    type="button"
    :class="{ active, danger }"
    @click="$emit('click')"
  >
    <component :is="icon" :filled="active" :size="20" />
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
  /* Phosphor glyphs sit ~2px inside their box; pull them back to the text edge. */
  margin-left: -2px;
}

.accountMenuButton:hover,
.accountMenuButton.active {
  background-color: var(--bg-2);
}

.accountMenuButton.active span {
  font-weight: bold;
}

.danger span,
.danger svg {
  color: var(--text-error);
}
</style>
