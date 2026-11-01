<script setup lang="ts">
defineProps<{
  message: string
  actionLabel?: string
}>()

defineEmits<{
  dismiss: []
  action: []
}>()
</script>

<template>
  <div class="errorBanner" role="alert">
    <span class="indicator" aria-hidden="true" />
    <p class="message">{{ message }}</p>
    <button v-if="actionLabel" class="actionButton" type="button" @click="$emit('action')">
      {{ actionLabel }}
    </button>
    <button class="dismissButton" type="button" aria-label="Dismiss" @click="$emit('dismiss')">
      &times;
    </button>
  </div>
</template>

<style scoped>
.errorBanner {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  width: 100%;
  padding: 0.6rem 0.6rem 0.6rem 1rem;
  border-radius: var(--radius-lg);
  background-color: var(--surface-raised);
  box-shadow: var(--shadow-lg);
}

.indicator {
  width: 0.5rem;
  height: 0.5rem;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  background-color: var(--danger);
}

.message {
  flex: 1;
  color: var(--text-1);
  line-height: 1.35;
}

.actionButton {
  flex-shrink: 0;
  height: var(--control-sm);
  padding: 0 0.75rem;
  border: none;
  border-radius: var(--radius-md);
  background-color: var(--accent-fill);
  color: var(--accent-text);
  font-size: var(--text-subhead);
  font-weight: 600;
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .actionButton:hover {
    background-color: var(--accent-fill-hover);
  }
}

.actionButton:active {
  background-color: var(--accent-fill-pressed);
}

.dismissButton {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 2rem;
  height: 2rem;
  border: none;
  background: none;
  font-size: 1.25rem;
  line-height: 1;
  border-radius: var(--radius-full);
  cursor: pointer;
  color: var(--text-2);
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .dismissButton:hover {
    background-color: var(--fill-hover);
  }
}

.dismissButton:active {
  background-color: var(--fill-pressed);
}
</style>
