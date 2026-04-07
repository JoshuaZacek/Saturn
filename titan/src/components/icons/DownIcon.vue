<script setup lang="ts">
withDefaults(
  defineProps<{
    size?: number | string
  }>(),
  {
    size: 20,
  },
)
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 256 256"
    :width="size"
    :height="size"
    class="icon"
    aria-hidden="true"
  >
    <path
      d="M216.49,104.49l-80,80a12,12,0,0,1-17,0l-80-80a12,12,0,1,1,17-17L128,159l71.51-71.52a12,12,0,0,1,17,17Z"
    />
  </svg>
</template>

<style scoped>
.icon {
  display: inline-block;
  flex-shrink: 0;
  color: var(--text-1);
  fill: currentColor;
}
</style>
