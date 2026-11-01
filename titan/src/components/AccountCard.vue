<template>
  <!-- Logged out: the two ways in, which open the log-in sheet. -->
  <div v-if="!authStore.loggedIn" class="accountCard guest">
    <SubmitButton class="guestButton" variant="secondary" @click="uiStore.openAuth('signup')">
      Sign up
    </SubmitButton>
    <SubmitButton class="guestButton" @click="uiStore.openAuth('login')">Log in</SubmitButton>
  </div>

  <div
    v-else
    ref="accountCard"
    class="accountCard"
    :class="{ open: !isMenuClosed }"
    @keydown.escape="isMenuClosed = true"
  >
    <button
      class="header"
      type="button"
      :aria-expanded="!isMenuClosed"
      aria-controls="account-menu"
      @click="isMenuClosed = !isMenuClosed"
    >
      <UserAvatar
        :name="username"
        :color="authStore.user.avatar_color"
        :image="authStore.user.avatar_image"
        :size="28"
      />
      <span class="headerName">@{{ username }}</span>
      <CaretIcon class="caret" :direction="isMenuClosed ? 'up' : 'down'" />
    </button>

    <Transition
      @before-enter="beforeMenuEnter"
      @enter="enterMenu"
      @before-leave="beforeMenuLeave"
      @leave="leaveMenu"
    >
      <div v-if="!isMenuClosed" id="account-menu" ref="menuContent" class="menuContent">
        <div class="accountLinks">
          <div class="accountLinksDivider" role="separator" />
          <AccountMenuButton
            label="Your profile"
            :icon="ProfileIcon"
            @click="goTo({ name: 'profile', params: { username } })"
          />
          <AccountMenuButton label="Settings" :icon="GearIcon" @click="goTo('/settings')" />
          <div class="accountLinksDivider" role="separator" />
          <AccountMenuButton label="Log out" :icon="SignOutIcon" danger @click="logout" />
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue'
import { useRouter, type RouteLocationRaw } from 'vue-router'
import AccountMenuButton from '@/components/AccountMenuButton.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import CaretIcon from '@/components/icons/CaretIcon.vue'
import GearIcon from '@/components/icons/GearIcon.vue'
import ProfileIcon from '@/components/icons/ProfileIcon.vue'
import SignOutIcon from '@/components/icons/SignOutIcon.vue'
import { useLogout } from '@/composables/useLogout'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'

const MENU_TRANSITION_MS = 220
// Matches --ease-out in App.vue.
const MENU_EASING = 'cubic-bezier(0.2, 0.8, 0.2, 1)'
const MENU_TRANSITION = ['height', 'opacity', 'margin-top', 'margin-bottom']
  .map((property) => `${property} ${MENU_TRANSITION_MS}ms ${MENU_EASING}`)
  .join(', ')

const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUIStore()
const logout = useLogout()

const isMenuClosed = ref(true)
const accountCard = useTemplateRef<HTMLDivElement>('accountCard')
const username = computed(() => String(authStore.user.username ?? ''))

const handleDocumentPointerDown = (event: PointerEvent) => {
  const root = accountCard.value
  if (!root || isMenuClosed.value) {
    return
  }

  if (!root.contains(event.target as Node | null)) {
    isMenuClosed.value = true
  }
}

onMounted(() => document.addEventListener('pointerdown', handleDocumentPointerDown))
onBeforeUnmount(() => document.removeEventListener('pointerdown', handleDocumentPointerDown))

// The menu opens and closes by its real height, margins included.
const beforeMenuEnter = (el: Element) => {
  const menu = el as HTMLElement
  const { marginTop, marginBottom } = getComputedStyle(menu)
  menu.dataset.targetMarginTop = marginTop
  menu.dataset.targetMarginBottom = marginBottom
  menu.style.height = '0'
  menu.style.marginTop = '0'
  menu.style.marginBottom = '0'
  menu.style.opacity = '0'
  menu.style.overflow = 'hidden'
}

const enterMenu = (el: Element) => {
  const menu = el as HTMLElement
  const targetMarginTop = menu.dataset.targetMarginTop ?? '0px'
  const targetMarginBottom = menu.dataset.targetMarginBottom ?? '0px'
  menu.style.transition = MENU_TRANSITION

  requestAnimationFrame(() => {
    menu.style.height = `${menu.scrollHeight}px`
    menu.style.marginTop = targetMarginTop
    menu.style.marginBottom = targetMarginBottom
    menu.style.opacity = '1'
  })

  const onTransitionEnd = (event: TransitionEvent) => {
    if (event.propertyName !== 'height') {
      return
    }

    menu.style.height = 'auto'
    menu.style.marginTop = ''
    menu.style.marginBottom = ''
    menu.style.overflow = ''
    menu.style.transition = ''
    menu.removeEventListener('transitionend', onTransitionEnd)
  }

  menu.addEventListener('transitionend', onTransitionEnd)
}

const beforeMenuLeave = (el: Element) => {
  const menu = el as HTMLElement
  const { marginTop, marginBottom } = getComputedStyle(menu)
  menu.style.height = `${menu.scrollHeight}px`
  menu.style.marginTop = marginTop
  menu.style.marginBottom = marginBottom
  menu.style.opacity = '1'
  menu.style.overflow = 'hidden'
}

const leaveMenu = (el: Element) => {
  const menu = el as HTMLElement
  menu.style.transition = MENU_TRANSITION

  requestAnimationFrame(() => {
    menu.style.height = '0'
    menu.style.marginTop = '0'
    menu.style.marginBottom = '0'
    menu.style.opacity = '0'
  })
}

const goTo = (to: RouteLocationRaw) => {
  isMenuClosed.value = true
  void router.push(to)
}
</script>

<style scoped>
.accountCard {
  position: sticky;
  bottom: 0;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  width: 100%;
  margin-top: auto;
  padding: 0.5rem 0.625rem;
  border-radius: var(--radius-lg) var(--radius-lg) 0 0;
  background-color: var(--surface-raised);
  box-shadow: var(--shadow-lg);
}

.guest {
  flex-direction: row;
  gap: 0.5rem;
  padding: 0.75rem;
}

.guestButton {
  flex: 1;
}

/* The whole row toggles the menu. */
.header {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  width: 100%;
  min-height: 2.75rem;
  padding: 0 0.5rem 0 0.375rem;
  border: none;
  border-radius: var(--radius-md);
  background: none;
  font-size: var(--text-body);
  text-align: left;
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .header:hover {
    background-color: var(--fill-hover);
  }
}

.header:active {
  background-color: var(--fill-pressed);
}

.headerName {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 600;
}

.caret {
  flex-shrink: 0;
  color: var(--text-2);
}

.menuContent {
  /* A block formatting context, so nothing inside collapses margins through
     its edges. Without it the open animation measures a different layout
     (overflow: hidden makes one) than the one it settles into, and snaps. */
  display: flow-root;
  margin-top: 0.25rem;
  /* The rows line up with the header's avatar. */
  padding: 0 0.375rem;
}

.accountLinks {
  display: grid;
}

.accountLinksDivider {
  height: 1px;
  margin: 0.25rem 0;
  background-color: var(--separator);
}

.accountLinksDivider:first-child {
  margin-top: 0;
}
</style>
