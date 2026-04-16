<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    :width="props.size + 'px'"
    :height="props.size + 'px'"
    :fill="props.color"
    viewBox="0 0 256 256"
  >
    <path
      :d="
        props.direction == 'up'
          ? 'M212.24,164.24a6,6,0,0,1-8.48,0L128,88.49,52.24,164.24a6,6,0,0,1-8.48-8.48l80-80a6,6,0,0,1,8.48,0l80,80A6,6,0,0,1,212.24,164.24Z'
          : 'M212.24,100.24l-80,80a6,6,0,0,1-8.48,0l-80-80a6,6,0,0,1,8.48-8.48L128,167.51l75.76-75.75a6,6,0,0,1,8.48,8.48Z'
      "
    ></path>
  </svg>
</template>

<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    size?: number
    color?: string
    direction?: 'up' | 'down'
  }>(),
  {
    size: 20,
    color: 'var(--text-1)',
    direction: 'down',
  },
)
</script>
