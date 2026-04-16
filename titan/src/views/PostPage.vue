<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const post_id = computed(() => route.params.post_id as string)
</script>

<template>
  <main>
    <h1>Post</h1>
    <h2>{{ post_id }}</h2>

    <nav>
      <RouterLink to="/">Home</RouterLink>
      <RouterLink :to="{ name: 'all' }">All</RouterLink>
      <RouterLink :to="{ name: 'moon', params: { moon: 'news' } }">Moon</RouterLink>
      <RouterLink :to="{ name: 'post', params: { post_id: '123' } }">Post</RouterLink>
    </nav>
  </main>
</template>
