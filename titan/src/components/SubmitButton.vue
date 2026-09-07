<script setup lang="ts">
defineProps<{
  type?: 'button' | 'submit' | 'reset'
  disabled?: boolean
}>()
</script>

<template>
  <button class="submitButton" :type="type ?? 'button'" :disabled="disabled">
    <slot />
  </button>
</template>

<style scoped>
.submitButton {
  background-color: var(--accent-color);
  border: none;
  font-size: 1rem;
  padding: 0.5rem 0.75rem;
  border-radius: 10px;
  cursor: pointer;
  color: var(--accent-text);
}
</style>
