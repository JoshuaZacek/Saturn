<template>
  <main>
    <h1>Unauthorized</h1>
    <p>{{ message }}</p>
    <p>You can log in or sign up from the account card at the bottom of the sidebar.</p>

    <RouterLink class="linkButton" :to="{ name: 'all', query: { sort: 'top', t: 'day' } }">
      Browse top posts
    </RouterLink>
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
  margin-top: 0.75rem;
}

.linkButton {
  display: inline-block;
  margin-top: 1.5rem;
  color: var(--text-2);
  background: var(--bg-2);
  padding: 0.5rem 0.9rem;
  border-radius: 10px;
  text-decoration: none;
}

.linkButton:hover {
  background: var(--bg-3);
}
</style>
