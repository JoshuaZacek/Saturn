<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const username = computed(() => route.params.username as string)
</script>

<template>
  <main>
    <h1>Profile</h1>
    <h2>{{ username }}</h2>

    <nav>
      <RouterLink to="/">Subscribed</RouterLink>
      <RouterLink :to="{ name: 'all' }">All</RouterLink>
      <RouterLink :to="{ name: 'moon', params: { moon: 'news' } }">Moon</RouterLink>
      <RouterLink :to="{ name: 'post', params: { post_id: '123' } }">Post</RouterLink>
    </nav>
  </main>
</template>
