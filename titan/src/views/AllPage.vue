<script setup lang="ts"></script>

<template>
  <main>
    <h1>All</h1>

    <nav>
      <RouterLink to="/">Subscribed</RouterLink>
      <RouterLink :to="{ name: 'all' }">All</RouterLink>
      <RouterLink :to="{ name: 'moon', params: { moon: 'news' } }">Moon</RouterLink>
      <RouterLink :to="{ name: 'post', params: { post_id: '123' } }">Post</RouterLink>
    </nav>
  </main>
</template>
