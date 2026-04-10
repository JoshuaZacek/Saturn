<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    size?: number | string
  }>(),
  {
    size: 16,
  },
)

const pathData =
  'M128,26A102,102,0,1,0,230,128,102.12,102.12,0,0,0,128,26ZM71.44,198a66,66,0,0,1,113.12,0,89.8,89.8,0,0,1-113.12,0ZM94,120a34,34,0,1,1,34,34A34,34,0,0,1,94,120Zm99.51,69.64a77.53,77.53,0,0,0-40-31.38,46,46,0,1,0-51,0,77.53,77.53,0,0,0-40,31.38,90,90,0,1,1,131,0Z'
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 256 256"
    :width="props.size"
    :height="props.size"
    class="icon"
    aria-hidden="true"
  >
    <path :d="pathData" />
  </svg>
</template>

<style scoped>
svg {
  fill: var(--text-2);
}
</style>
