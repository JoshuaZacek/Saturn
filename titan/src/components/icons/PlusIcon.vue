<script setup lang="ts">
withDefaults(
  defineProps<{
    size?: number | string
  }>(),
  {
    size: 22,
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
      d="M224,120H136V32a8,8,0,0,0-16,0v88H32a8,8,0,0,0,0,16h88v88a8,8,0,0,0,16,0V136h88a8,8,0,0,0,0-16Z"
    />
  </svg>
</template>

<style scoped>
.icon {
  display: inline-block;
  flex-shrink: 0;
  color: var(--text-1);
}
</style>
