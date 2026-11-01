<script setup lang="ts">
import type { Component } from 'vue'

// What a list shows when there's nothing in it: what's missing, and (in the
// default slot) the next thing to do about it.
defineProps<{
  title: string
  description?: string
  icon?: Component
}>()
</script>

<template>
  <div class="emptyState">
    <span v-if="icon" class="emptyIcon" aria-hidden="true">
      <component :is="icon" :size="24" />
    </span>
    <p class="emptyTitle">{{ title }}</p>
    <p v-if="description" class="emptyDescription">{{ description }}</p>
    <div v-if="$slots.default" class="emptyActions">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.emptyState {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2.5rem 1rem;
  text-align: center;
}

.emptyIcon {
  display: inline-grid;
  place-items: center;
  width: 3rem;
  height: 3rem;
  margin-bottom: 0.9rem;
  border-radius: var(--radius-full);
  background-color: var(--fill-secondary);
  color: var(--text-2);
}

.emptyTitle {
  font-size: var(--text-reading);
  font-weight: 600;
  letter-spacing: var(--tracking-snug);
}

.emptyDescription {
  max-width: 26rem;
  margin-top: 0.3rem;
  font-size: var(--text-subhead);
  line-height: 1.45;
  color: var(--text-2);
}

.emptyActions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 0.5rem;
  margin-top: 1.1rem;
}
</style>
