<script setup lang="ts">
withDefaults(
  defineProps<{
    size?: number | string
    color?: string
  }>(),
  {
    size: 22,
    color: 'var(--text-1)',
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
    :style="{ stroke: color }"
    aria-hidden="true"
  >
    <path
      d="M48 136 L96 184 L208 72"
      fill="none"
      stroke-width="24"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  </svg>
</template>

<style scoped>
.icon {
  display: inline-block;
  flex-shrink: 0;
}
</style>
