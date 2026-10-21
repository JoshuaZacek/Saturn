<script setup lang="ts">
import type { Component } from 'vue'

defineProps<{
  type?: 'button' | 'submit' | 'reset'
  disabled?: boolean
  variant?: 'default' | 'secondary' | 'danger'
  // An icon component (taking `size`) shown before the label, in the label's colour.
  icon?: Component
}>()
</script>

<template>
  <button
    class="submitButton"
    :class="[variant, { withIcon: icon }]"
    :type="type ?? 'button'"
    :disabled="disabled"
  >
    <component :is="icon" v-if="icon" class="buttonIcon" :size="18" />
    <slot />
  </button>
</template>

<style scoped>
.submitButton {
  background-color: var(--accent-color);
  border: none;
  font-size: 1rem;
  padding: 0.5rem 0.75rem;
  height: 2.25rem;
  border-radius: 10px;
  cursor: pointer;
  color: var(--accent-text);
  transition: opacity 0.15s ease;
}

.submitButton.withIcon {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding-left: 0.65rem;
}

/* The global `* { color }` rule and the icons' own `.icon { color }` reach the
   icon and its <path>, so hand the button's colour down explicitly (with enough
   specificity to beat `.icon`). */
.submitButton .buttonIcon,
.submitButton .buttonIcon :deep(path) {
  color: inherit;
  fill: currentColor;
}

.submitButton.secondary {
  background-color: var(--bg-2);
  color: var(--text-1);
}

.submitButton.danger {
  background-color: var(--text-error);
}

.submitButton:disabled {
  cursor: default;
  opacity: 0.75;
}
</style>
