<script setup lang="ts">
defineProps<{
  message: string
}>()

defineEmits<{
  dismiss: []
}>()
</script>

<template>
  <div class="errorBanner" role="alert">
    <p class="message">{{ message }}</p>
    <button class="dismissButton" type="button" aria-label="Dismiss" @click="$emit('dismiss')">
      &times;
    </button>
  </div>
</template>

<style scoped>
.errorBanner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.6rem 0.75rem 0.6rem 1rem;
  border: 1px solid var(--text-error);
  border-radius: 10px;
  background-color: var(--bg-sub);
}

.message {
  flex: 1;
  color: var(--text-error);
}

.dismissButton {
  border: none;
  background: none;
  font-size: 1.25rem;
  line-height: 1;
  padding: 0.25rem 0.4rem;
  border-radius: 8px;
  cursor: pointer;
  color: var(--text-2);
}

.dismissButton:hover {
  background-color: var(--bg-2);
}
</style>
