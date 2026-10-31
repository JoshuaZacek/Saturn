<script setup lang="ts">
import { useUIStore } from '@/stores/ui'
import CreateActionsSelect from '@/components/CreateActionsSelect.vue'
import CloseIcon from '@/components/icons/CloseIcon.vue'
import MenuIcon from '@/components/icons/MenuIcon.vue'

const uiStore = useUIStore()
</script>

<!-- Shown instead of the sidebar on small screens; the menu button opens the
     sidebar as a drawer underneath it. -->
<template>
  <header class="appTopBar">
    <button
      class="menuButton"
      type="button"
      aria-label="Menu"
      aria-controls="appSidebar"
      :aria-expanded="uiStore.isSidebarOpen"
      @click="uiStore.toggleSidebar"
    >
      <CloseIcon v-if="uiStore.isSidebarOpen" :size="24" />
      <MenuIcon v-else :size="24" />
    </button>

    <router-link class="logoLink" to="/">
      <img class="logo" width="36" height="36" src="/logo.png" alt="Logo" />
    </router-link>

    <CreateActionsSelect class="createActions" />
  </header>
</template>

<style scoped>
.appTopBar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 30;
  height: var(--top-bar-height);
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0 0.75rem 0 0.5rem;
  border-bottom: 1px solid var(--bg-2);
  background-color: var(--bg-1);
  user-select: none;
}

/* Same circle as the Create (+) button on the other side, a little larger
   for fingers. */
.menuButton {
  width: 2.5rem;
  height: 2.5rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: 999px;
  background: transparent;
  cursor: pointer;
}

.menuButton:hover {
  background-color: var(--bg-2);
}

.logoLink {
  display: inline-flex;
}

.logo {
  user-select: none;
  -webkit-user-drag: none;
}

.createActions {
  margin-left: auto;
}
</style>
