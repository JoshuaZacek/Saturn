<template>
  <main>
    <h1>Unauthorized</h1>
    <p>You must be logged in to create a post</p>

    <nav>
      <RouterLink to="/">Home</RouterLink>
      <RouterLink :to="{ name: 'all' }">All</RouterLink>
    </nav>
  </main>
</template>

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
