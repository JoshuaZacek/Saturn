<script setup lang="ts">
import WarningIcon from '@/components/icons/WarningIcon.vue'

defineProps<{
  message: string
}>()
</script>

<template>
  <!-- A quiet, centred notice for pages with nothing else to show. -->
  <main class="statusMessage">
    <WarningIcon class="statusIcon" :size="56" />
    <h1 class="statusText">{{ message }}</h1>
  </main>
</template>

<style scoped>
.statusMessage {
  width: 100%;
  min-height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  /* Sits a little above true centre, where the eye expects it. */
  padding: 2rem 0 6rem;
  text-align: center;
  color: var(--text-3);
  animation: status-in var(--duration-slow) var(--ease-out);
}

.statusText {
  max-width: 28rem;
  font-size: 1.25rem;
  font-weight: 500;
  letter-spacing: -0.01em;
  line-height: 1.35;
  color: var(--text-3);
}

@keyframes status-in {
  from {
    opacity: 0;
    transform: translateY(4px);
  }
}

@media (prefers-reduced-motion: reduce) {
  .statusMessage {
    animation: none;
  }
}
</style>
