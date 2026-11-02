<script setup lang="ts">
import { computed } from 'vue'
import ActionMenu, { type ActionMenuItem } from '@/components/ActionMenu.vue'
import CreateActionsSelect from '@/components/CreateActionsSelect.vue'
import NotificationBell from '@/components/NotificationBell.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import CloseIcon from '@/components/icons/CloseIcon.vue'
import GearIcon from '@/components/icons/GearIcon.vue'
import MenuIcon from '@/components/icons/MenuIcon.vue'
import ProfileIcon from '@/components/icons/ProfileIcon.vue'
import SignOutIcon from '@/components/icons/SignOutIcon.vue'
import { useLogout } from '@/composables/useLogout'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'

const authStore = useAuthStore()
const uiStore = useUIStore()
const logout = useLogout()

const username = computed(() => String(authStore.user.username ?? ''))

// The same items as the sidebar's account card, in the same menu as Create (+).
const accountActions = computed<ActionMenuItem[]>(() => [
  {
    value: 'profile',
    label: 'Your profile',
    icon: ProfileIcon,
    to: { name: 'profile', params: { username: username.value } },
  },
  { value: 'settings', label: 'Settings', icon: GearIcon, to: { name: 'settings' } },
  { value: 'logout', label: 'Log out', icon: SignOutIcon, danger: true, separated: true },
])

const onAccountAction = (action: string) => {
  if (action === 'logout') {
    void logout()
  }
}
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
      <img class="logo" width="36" height="36" src="/logo.png" alt="Saturn home" />
    </router-link>

    <div class="topActions">
      <template v-if="authStore.isLoggedIn">
        <NotificationBell />
        <CreateActionsSelect />
        <ActionMenu
          class="accountMenu"
          label="Account"
          :items="accountActions"
          size="lg"
          @select="onAccountAction"
        >
          <template #trigger>
            <UserAvatar
              :name="username"
              :color="authStore.user.avatar_color"
              :image="authStore.user.avatar_image"
              :size="30"
            />
          </template>
        </ActionMenu>
      </template>
      <SubmitButton v-else size="sm" @click="uiStore.openAuth('login')">Log in</SubmitButton>
    </div>
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
  border-bottom: 1px solid var(--separator);
  background-color: var(--top-bar-bg);
  -webkit-backdrop-filter: saturate(180%) blur(20px);
  backdrop-filter: saturate(180%) blur(20px);
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
  border-radius: var(--radius-full);
  background: transparent;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .menuButton:hover {
    background-color: var(--fill-hover);
  }
}

.menuButton:active {
  background-color: var(--fill-pressed);
  transform: scale(0.95);
}

.logoLink {
  display: inline-flex;
  border-radius: var(--radius-full);
}

.logo {
  user-select: none;
  -webkit-user-drag: none;
  filter: var(--logo-filter);
}

.topActions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-left: auto;
}

/* Both menu buttons: the same circle as the menu button on the left. */
.topActions :deep(.trigger) {
  width: 2.5rem;
  height: 2.5rem;
}
</style>
