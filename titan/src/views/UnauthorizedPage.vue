<template>
  <main>
    <h1>Unauthorized</h1>
    <p>{{ message }}</p>

    <nav>
      <RouterLink to="/">Home</RouterLink>
      <RouterLink :to="{ name: 'all' }">All</RouterLink>
    </nav>
  </main>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const message = computed(() => {
  const queryMessage = route.query.message
  return typeof queryMessage === 'string' ? queryMessage : 'You must be logged in to do that'
})
</script>

<style scoped>
main {
  width: 40rem;
}

p {
  color: var(--text-2);
  margin: 0.75rem 0 1rem;
}

nav {
  display: flex;
  gap: 0.8rem;
}
</style>
