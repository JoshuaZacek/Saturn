<template>
  <main>
    <h1>Home</h1>

    <nav>
      <RouterLink to="/">Home</RouterLink>
      <RouterLink :to="{ name: 'all' }">All</RouterLink>
      <RouterLink :to="{ name: 'moon', params: { moon: 'news' } }">Moon</RouterLink>
      <RouterLink :to="{ name: 'post', params: { post_id: '123' } }">Post</RouterLink>
    </nav>
  </main>
</template>
