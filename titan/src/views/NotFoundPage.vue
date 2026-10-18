<template>
  <main>
    <h1>Content does not exist</h1>
    <p>
      The content you requested may have been modified or deleted, or it may have a different
      spelling.
    </p>

    <RouterLink class="linkButton" :to="{ name: 'all', query: { sort: 'top', t: 'day' } }">
      Browse top posts
    </RouterLink>
  </main>
</template>

<style scoped>
main {
  width: 40rem;
}

p {
  color: var(--text-2);
  margin: 0.75rem 0 1.5rem;
}

.linkButton {
  display: inline-block;
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
