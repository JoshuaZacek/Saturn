<template>
  <input :class="hasError ? 'error' : ''" v-bind="$attrs" />
</template>

<style scoped>
input {
  display: block;
  width: 100%;
  height: 2rem;
  border: 1px solid var(--bg-2);
  border-bottom: none;
  padding: 1.25rem 0.75rem;
  font-size: 1rem;
  color: var(--text-1);
}

input:focus {
  position: relative;
  z-index: 1;
}

input:first-child {
  border-top-left-radius: 10px;
  border-top-right-radius: 10px;
}

input:last-child {
  border-bottom-left-radius: 10px;
  border-bottom-right-radius: 10px;
  border-bottom: solid 1px var(--bg-2);
}

input::placeholder {
  color: var(--text-3);
}

input:-webkit-autofill,
input:-webkit-autofill:hover,
input:-webkit-autofill:focus,
input:-webkit-autofill:active {
  transition: background-color 5500s ease-in-out 0s;
  -webkit-text-fill-color: var(--text-1) !important;
}

input.error {
  background-color: var(--bg-error);
}

input.error::placeholder {
  color: var(--text-error);
}
</style>

<script setup lang="ts">
defineProps<{
  hasError?: boolean
}>()
</script>
