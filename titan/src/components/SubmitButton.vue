<script setup lang="ts">
defineProps<{
  type?: 'button' | 'submit' | 'reset'
  disabled?: boolean
  variant?: 'default' | 'danger'
}>()
</script>

<template>
  <button
    class="submitButton"
    :class="{ danger: variant === 'danger' }"
    :type="type ?? 'button'"
    :disabled="disabled"
  >
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

.submitButton.danger {
  background-color: var(--text-error);
}

.submitButton:disabled {
  cursor: default;
  opacity: 0.75;
}
</style>
