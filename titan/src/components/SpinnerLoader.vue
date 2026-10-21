<template>
  <div class="spinner" :style="spinnerStyle" role="status" aria-live="polite" aria-label="Loading">
    <span v-for="n in 12" :key="n" class="tick" :style="{ '--tick-index': String(n - 1) }" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    size?: number
    bgColor?: string
    fgColor?: string
  }>(),
  {
    size: 40,
    bgColor: 'var(--bg-1)',
    fgColor: 'var(--text-1)',
  },
)

const spinnerStyle = computed(() => {
  const spinnerSize = Math.max(12, Math.round(props.size))
  const tickWidth = Math.max(2, Math.round(spinnerSize * 0.11))
  const tickHeight = Math.max(6, Math.round(spinnerSize * 0.32))

  return {
    '--spinner-size': `${spinnerSize}px`,
    '--spinner-bg-color': props.bgColor,
    '--spinner-fg-color': props.fgColor,
    '--tick-width': `${tickWidth}px`,
    '--tick-height': `${tickHeight}px`,
  } as Record<string, string>
})
</script>

<style scoped>
.spinner {
  position: relative;
  display: inline-block;
  width: var(--spinner-size);
  height: var(--spinner-size);
}

.tick {
  position: absolute;
  inset: 0;
  transform: rotate(calc(var(--tick-index) * 30deg));
}

.tick::before {
  content: '';
  position: absolute;
  left: 50%;
  top: 0;
  width: var(--tick-width);
  height: var(--tick-height);
  margin-left: calc(var(--tick-width) / -2);
  border-radius: 999px;
  background-color: var(--spinner-bg-color);
}

.tick::after {
  content: '';
  position: absolute;
  left: 50%;
  top: 0;
  width: var(--tick-width);
  height: var(--tick-height);
  margin-left: calc(var(--tick-width) / -2);
  border-radius: 999px;
  background-color: var(--spinner-fg-color);
  animation: ios-fade 1s linear infinite;
  animation-delay: calc((var(--tick-index) * 0.083333s) - 1s);
  will-change: opacity;
}

@keyframes ios-fade {
  0% {
    opacity: 1;
  }

  100% {
    opacity: 0;
  }
}
</style>
