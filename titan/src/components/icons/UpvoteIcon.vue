<script setup lang="ts">
// The vote buttons' up arrow, filled, as a plain icon (upvote milestones).
withDefaults(defineProps<{ size?: number | string }>(), { size: 20 })
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
      d="M231.39,123.06A8,8,0,0,1,224,128H184v80a16,16,0,0,1-16,16H88a16,16,0,0,1-16-16V128H32a8,8,0,0,1-5.66-13.66l96-96a8,8,0,0,1,11.32,0l96,96A8,8,0,0,1,231.39,123.06Z"
    />
  </svg>
</template>

<style scoped>
.icon {
  display: inline-block;
  flex-shrink: 0;
  fill: currentColor;
}
</style>
