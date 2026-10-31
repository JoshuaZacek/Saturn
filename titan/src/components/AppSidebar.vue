<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSubscriptionsStore } from '@/stores/subscriptions'
import { useUIStore } from '@/stores/ui'
import FeedButton from '@/components/FeedButton.vue'
import AccountCard from '@/components/AccountCard.vue'
import CreateActionsSelect from '@/components/CreateActionsSelect.vue'
import NewIcon from '@/components/icons/NewIcon.vue'
import HomeIcon from '@/components/icons/HomeIcon.vue'
import TopIcon from '@/components/icons/TopIcon.vue'
import { isCorrectTimePeriod } from '@/router/index.ts'

const router = useRouter()
const route = useRoute()
const uiStore = useUIStore()
const authStore = useAuthStore()
const subscriptionsStore = useSubscriptionsStore()
const getSingleQueryValue = (value: unknown) => (Array.isArray(value) ? value[0] : value)

const sortQuery = computed(() => getSingleQueryValue(route.query.sort))
const tQuery = computed(() => getSingleQueryValue(route.query.t))
const currentTitle = computed(() => {
  if (route.name === 'moon') {
    return `/${route.params.moon}`
  } else if (route.name === 'post') {
    return 'Post'
  } else if (route.name === 'create-post') {
    return 'Create post...'
  } else if (route.name === 'create-moon') {
    return 'Create moon...'
  } else if (route.name === 'profile') {
    return `@${route.params.username}`
  } else if (route.name === 'settings') {
    return 'Settings'
  }

  return ''
})

const isNotFoundPage = computed(() => route.name === 'not-found')
const isHomePage = computed(() => route.name === 'home')
const isTopPage = computed(
  () => route.name === 'all' && sortQuery.value === 'top' && isCorrectTimePeriod(tQuery.value),
)
const isNewPage = computed(() => route.name === 'all' && sortQuery.value === 'new')
const isUnauthorizedPage = computed(() => route.name === 'unauthorized')

const isMoonPage = (name: string) => route.name === 'moon' && route.params.moon === name
// A subscribed moon is already highlighted in the Subscriptions list.
const isSubscribedMoonPage = computed(() =>
  subscriptionsStore.moons.some((moon) => isMoonPage(moon.name)),
)

watch(
  () => authStore.isLoggedIn,
  (loggedIn) => {
    if (loggedIn) {
      void subscriptionsStore.load()
    } else {
      subscriptionsStore.clear()
    }
  },
  { immediate: true },
)

const goToHome = () => {
  router.push({ name: 'home' })
}

const goToTop = () => {
  router.push({ name: 'all', query: { sort: 'top', t: 'day' } })
}

const goToNew = () => {
  router.push({ name: 'all', query: { sort: 'new' } })
}

const isResizing = ref(false)

const stopResizing = () => {
  if (!isResizing.value) {
    return
  }

  isResizing.value = false
  document.body.style.cursor = ''
  document.body.style.userSelect = ''
  window.removeEventListener('pointermove', onPointerMove)
  window.removeEventListener('pointerup', stopResizing)
}

const onPointerMove = (event: PointerEvent) => {
  if (!isResizing.value) {
    return
  }

  uiStore.setSidebarWidth(event.clientX)
}

const startResizing = (event: PointerEvent) => {
  event.preventDefault()
  isResizing.value = true
  document.body.style.cursor = 'col-resize'
  document.body.style.userSelect = 'none'
  window.addEventListener('pointermove', onPointerMove)
  window.addEventListener('pointerup', stopResizing)
}

// Anything that navigates from the drawer closes it, even to the page already shown.
const removeAfterEach = router.afterEach(() => uiStore.closeSidebar())

const onDocumentKeydown = (event: KeyboardEvent) => {
  // An open select handles its own Escape first.
  if (event.key === 'Escape' && !event.defaultPrevented && uiStore.isSidebarOpen) {
    uiStore.closeSidebar()
  }
}

onMounted(() => {
  uiStore.initSidebarWidth()
  document.addEventListener('keydown', onDocumentKeydown)
})

onBeforeUnmount(() => {
  stopResizing()
  removeAfterEach()
  document.removeEventListener('keydown', onDocumentKeydown)
})
</script>

<template>
  <aside
    id="appSidebar"
    class="sidebar"
    :class="{
      resizing: isResizing,
      drawer: uiStore.isCompactLayout,
      drawerOpen: uiStore.isSidebarOpen,
    }"
    :style="uiStore.isCompactLayout ? undefined : { width: `${uiStore.sidebarWidthPx}px` }"
  >
    <!-- On small screens the top bar has the logo and Create menu instead. -->
    <div v-if="!uiStore.isCompactLayout" class="topBar">
      <router-link to="/">
        <img class="logo" width="50" height="50" src="/logo.png" alt="Logo" />
      </router-link>

      <CreateActionsSelect />
    </div>

    <div
      v-if="
        !isHomePage &&
        !isTopPage &&
        !isNewPage &&
        !isNotFoundPage &&
        !isUnauthorizedPage &&
        !isSubscribedMoonPage
      "
      class="feedsGroup"
    >
      <p class="groupTitle">Currently Viewing</p>
      <FeedButton :label="currentTitle" :active="true" />
    </div>

    <div class="feedsGroup">
      <p class="groupTitle">Feeds</p>
      <FeedButton label="Home" :icon="HomeIcon" :active="isHomePage" @click="goToHome" />
      <FeedButton label="Top" :icon="TopIcon" :active="isTopPage" @click="goToTop" />
      <FeedButton label="New" :icon="NewIcon" :active="isNewPage" @click="goToNew" />
    </div>

    <div v-if="subscriptionsStore.moons.length > 0" class="feedsGroup">
      <p class="groupTitle">Subscriptions</p>
      <FeedButton
        v-for="moon in subscriptionsStore.moons"
        :key="moon.id"
        class="subscriptionButton"
        :label="`/${moon.name}`"
        :active="isMoonPage(moon.name)"
        @click="router.push({ name: 'moon', params: { moon: moon.name } })"
      />
    </div>

    <AccountCard />

    <button
      v-if="!uiStore.isCompactLayout"
      class="resize-handle"
      type="button"
      aria-label="Resize sidebar"
      @pointerdown="startResizing"
      tabindex="-1"
    />
  </aside>

  <Transition name="backdrop-fade">
    <div
      v-if="uiStore.isCompactLayout && uiStore.isSidebarOpen"
      class="drawerBackdrop"
      aria-hidden="true"
      @click="uiStore.closeSidebar"
    />
  </Transition>
</template>

<style scoped>
.sidebar {
  position: relative;
  display: flex;
  flex-direction: column;
  height: 100%;
  min-width: 15rem;
  max-width: 30rem;
  border-right: 1px solid var(--bg-2);
  padding: 1rem;
  padding-bottom: 0rem;
  user-select: none;
  overflow-y: scroll;
  overflow-x: hidden;
  flex-shrink: 0;
}

/* Slides in from the left under the top bar. Hidden (so it can't be focused)
   once it has slid out. */
.sidebar.drawer {
  position: fixed;
  top: var(--top-bar-height);
  bottom: 0;
  left: 0;
  z-index: 40;
  width: min(20rem, 85vw);
  height: auto;
  border-right: none;
  background-color: var(--bg-1);
  box-shadow: 0 5px 20px rgb(0 0 0 / 10%);
  overscroll-behavior: contain;
  visibility: hidden;
  transform: translateX(-100%);
  transition:
    transform 250ms ease,
    visibility 0s linear 250ms;
}

.sidebar.drawer.drawerOpen {
  visibility: visible;
  transform: none;
  transition: transform 250ms ease;
}

/* Without the logo row above it. */
.drawer > .feedsGroup:first-child {
  margin-top: 0.5rem;
}

.drawerBackdrop {
  position: fixed;
  inset: var(--top-bar-height) 0 0;
  z-index: 35;
  background-color: rgb(20 17 11 / 30%);
}

.backdrop-fade-enter-active,
.backdrop-fade-leave-active {
  transition: opacity 250ms ease;
}

.backdrop-fade-enter-from,
.backdrop-fade-leave-to {
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .sidebar.drawer,
  .sidebar.drawer.drawerOpen,
  .backdrop-fade-enter-active,
  .backdrop-fade-leave-active {
    transition: none;
  }
}

.logo {
  user-select: none;
  -webkit-user-drag: none;
  cursor: pointer;
}

.topBar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.resize-handle {
  position: absolute;
  top: 0;
  right: -3px;
  z-index: 2;
  width: 6px;
  height: 100%;
  border: 0;
  padding: 0;
  background: transparent;
  cursor: col-resize;
  /* Lets a finger drag it on touch screens instead of scrolling. */
  touch-action: none;
}

ul {
  padding-left: 1rem;
}

.feedsGroup {
  margin-top: 2rem;
}

.subscriptionButton {
  /* Icon-less FeedButtons are static labels by default; these navigate. */
  cursor: pointer;
}

.groupTitle {
  font-size: 0.75rem;
  text-transform: uppercase;
  color: var(--text-2);
  margin-bottom: 0.5rem;
}
</style>
