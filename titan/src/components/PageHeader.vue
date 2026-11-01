<script setup lang="ts">
// A page's title, with its toolbar (sort, filters, tabs) directly under it.
defineProps<{
  title?: string
}>()
</script>

<template>
  <header class="pageHeader">
    <h1 class="pageTitle">
      <slot name="title">{{ title }}</slot>
    </h1>
    <div v-if="$slots.default" class="pageToolbar">
      <slot />
    </div>
  </header>
</template>

<style scoped>
.pageHeader {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.25rem;
}

.pageTitle {
  overflow-wrap: anywhere;
}

.pageToolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}
</style>
