<script setup lang="ts">
import AppSidebar from '@/components/AppSidebar.vue'
</script>

<template>
  <AppSidebar />
  <main class="page-content">
    <RouterView />
  </main>
</template>

<style>
:root {
  --bg-1: #faf9f6;
  --bg-2: #ede9de;
  --bg-3: #d7cfb7;

  --text-1: #14110b;
  --text-2: #625737;
}

html,
body,
#app {
  background-color: var(--bg-1);
  width: 100%;
  height: 100%;
  position: relative;
}

* {
  margin: 0;
  padding: 0;
  font-family: Helvetica, Arial, sans-serif;
  box-sizing: border-box;
  color: var(--text-1);
}

#app {
  display: flex;
}

.page-content {
  flex: 1;
  display: flex;
  justify-content: center;
  padding: 5rem 0;
}
</style>
