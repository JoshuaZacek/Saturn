<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
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

const isHomePage = computed(() => route.name === 'home')
const isTopPage = computed(
  () => route.name === 'all' && sortQuery.value === 'top' && isCorrectTimePeriod(tQuery.value),
)
const isNewPage = computed(() => route.name === 'all' && sortQuery.value === 'new')

// The moon you're in: the moon page itself, or the moon of the post you're reading.
const contextMoon = computed(() => {
  if (route.name === 'moon') {
    return String(route.params.moon)
  }

  return route.name === 'post' ? uiStore.postMoonName : null
})

const isSubscribedTo = (name: string) => subscriptionsStore.moons.some((moon) => moon.name === name)
const isContextMoon = (name: string) => contextMoon.value === name

// "Currently viewing" names where you are when the lists above don't: a moon
// you're not subscribed to (a link back to it from one of its posts), or a
// person's profile. Other pages are already named by their own title.
const currentItem = computed(() => {
  if (route.name === 'profile') {
    const username = String(route.params.username)
    return {
      key: `@${username}`,
      label: `@${username}`,
      avatar: { name: username, shape: 'circle' as const },
      to: null,
    }
  }

  const moon = contextMoon.value
  if (moon && !isSubscribedTo(moon)) {
    return {
      key: `/${moon}`,
      label: `/${moon}`,
      avatar: { name: moon, shape: 'tile' as const },
      to: route.name === 'post' ? { name: 'moon', params: { moon } } : null,
    }
  }

  return null
})

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

// The selection highlight follows the active row. While "Currently viewing"
// opens or closes the rows move, so each frame aims at the row's live position
// and eases away the distance it started from.
const sidebarRef = ref<HTMLElement | null>(null)
const pill = reactive({ top: 0, height: 0, visible: false })
const PILL_MOVE_MS = 300
// Long enough to also follow the group's open/close animation to its end.
const PILL_TRACK_MS = 420
let pillFrame = 0

const findActiveRow = () =>
  Array.from(sidebarRef.value?.querySelectorAll<HTMLElement>('.feedButton.active') ?? []).find(
    (row) => !row.closest('.group-collapse-leave-active'),
  ) ?? null

const easeOutCubic = (t: number) => 1 - Math.pow(1 - t, 3)

const movePill = () => {
  cancelAnimationFrame(pillFrame)
  const target = findActiveRow()

  if (!target) {
    pill.visible = false
    return
  }

  // Appearing (or with reduced motion): start on the row instead of sliding in.
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  if (!pill.visible || reduceMotion) {
    pill.top = target.offsetTop
    pill.height = target.offsetHeight
    pill.visible = true
  }

  const startOffset = pill.top - target.offsetTop
  const start = performance.now()

  const step = (now: number) => {
    const row = findActiveRow()
    if (!row) {
      return
    }

    const elapsed = now - start
    const remaining = 1 - easeOutCubic(Math.min(1, elapsed / PILL_MOVE_MS))
    pill.top = row.offsetTop + startOffset * remaining
    pill.height = row.offsetHeight

    if (elapsed < PILL_TRACK_MS) {
      pillFrame = requestAnimationFrame(step)
    }
  }

  pillFrame = requestAnimationFrame(step)
}

watch(
  [
    () => route.fullPath,
    () => authStore.isLoggedIn,
    () => subscriptionsStore.moons.length,
    () => uiStore.isCompactLayout,
    () => uiStore.postMoonName,
  ],
  () => movePill(),
  { flush: 'post' },
)

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
  movePill()
  uiStore.initSidebarWidth()
  document.addEventListener('keydown', onDocumentKeydown)
})

onBeforeUnmount(() => {
  cancelAnimationFrame(pillFrame)
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
    ref="sidebarRef"
  >
    <!-- One highlight for the active row, which glides between rows. -->
    <span
      class="selectionPill"
      :class="{ visible: pill.visible }"
      :style="{ transform: `translateY(${pill.top}px)`, height: `${pill.height}px` }"
      aria-hidden="true"
    />
    <!-- On small screens the top bar has the logo and Create menu instead. -->
    <div v-if="!uiStore.isCompactLayout" class="topBar">
      <router-link class="logoLink" to="/">
        <img class="logo" width="50" height="50" src="/logo.png" alt="Saturn home" />
      </router-link>

      <CreateActionsSelect v-if="authStore.isLoggedIn" />
    </div>

    <!-- Opens and closes in place, so the rows below glide rather than jump. -->
    <Transition name="group-collapse">
      <div v-if="currentItem" class="feedsGroup currentGroup">
        <div class="collapsibleInner">
          <p class="groupTitle">Currently viewing</p>
          <FeedButton
            :key="currentItem.key"
            :label="currentItem.label"
            :avatar="currentItem.avatar"
            :active="true"
            :interactive="!!currentItem.to"
            :current="currentItem.to ? 'location' : 'page'"
            @click="currentItem.to && router.push(currentItem.to)"
          />
        </div>
      </div>
    </Transition>

    <div class="feedsGroup mainFeeds">
      <p class="groupTitle">Feeds</p>
      <FeedButton
        v-if="authStore.isLoggedIn"
        label="Home"
        :icon="HomeIcon"
        :active="isHomePage"
        @click="goToHome"
      />
      <FeedButton label="Top" :icon="TopIcon" :active="isTopPage" @click="goToTop" />
      <FeedButton label="New" :icon="NewIcon" :active="isNewPage" @click="goToNew" />
    </div>

    <div v-if="subscriptionsStore.moons.length > 0" class="feedsGroup">
      <p class="groupTitle">Subscriptions</p>
      <FeedButton
        v-for="moon in subscriptionsStore.moons"
        :key="moon.id"
        :label="`/${moon.name}`"
        :avatar="{ name: moon.name, shape: 'tile' }"
        :active="isContextMoon(moon.name)"
        :current="route.name === 'post' ? 'location' : 'page'"
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
  /* Its own stacking context, so the selection highlight can sit behind all
     of the sidebar's content without going behind the sidebar itself. */
  isolation: isolate;
  display: flex;
  flex-direction: column;
  height: 100%;
  min-width: 15rem;
  max-width: 30rem;
  border-right: 1px solid var(--separator);
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
  box-shadow: var(--shadow-lg);
  overscroll-behavior: contain;
  visibility: hidden;
  transform: translateX(-100%);
  transition:
    transform var(--duration-base) var(--ease-in-out),
    visibility 0s linear var(--duration-base);
}

.sidebar.drawer.drawerOpen {
  visibility: visible;
  transform: none;
  transition: transform var(--duration-slow) var(--ease-out);
}

/* Without the logo row above it. */
/* Without the logo row above them, the groups start higher. "Currently
   viewing" keeps its 2rem gap to Feeds as bottom margin, so neither group
   moves when it opens or closes. */
.drawer > .currentGroup {
  margin-top: 0.5rem;
  margin-bottom: 1.5rem;
}

.drawer > .currentGroup + .mainFeeds,
.drawer > .mainFeeds:first-of-type {
  margin-top: 0.5rem;
}

.drawerBackdrop {
  position: fixed;
  inset: var(--top-bar-height) 0 0;
  z-index: 35;
  background-color: var(--backdrop);
}

.backdrop-fade-enter-active,
.backdrop-fade-leave-active {
  transition: opacity var(--duration-slow) var(--ease-out);
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

.logoLink {
  display: inline-flex;
  border-radius: var(--radius-full);
}

.logo {
  user-select: none;
  -webkit-user-drag: none;
  cursor: pointer;
  filter: var(--logo-filter);
  transition: transform var(--duration-fast) var(--ease-out);
}

.logoLink:active .logo {
  transform: scale(0.95);
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

/* A hairline that firms up while the handle is hovered. */
.resize-handle::after {
  content: '';
  position: absolute;
  inset: 0 2px;
  background-color: var(--separator-strong);
  opacity: 0;
  transition: opacity var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .resize-handle:hover::after {
    opacity: 1;
  }
}

ul {
  padding-left: 1rem;
}

.feedsGroup {
  margin-top: 2rem;
}

.selectionPill {
  position: absolute;
  z-index: -1;
  top: 0;
  left: 1rem;
  right: 1rem;
  border-radius: var(--radius-md);
  background-color: var(--fill-secondary);
  opacity: 0;
  pointer-events: none;
  transition: opacity var(--duration-fast) var(--ease-out);
}

.selectionPill.visible {
  opacity: 1;
}

/* Height, fade and spacing together, as the group opens or closes. */
.currentGroup {
  display: grid;
  grid-template-rows: 1fr;
}

/* Anchored to the bottom, so the row (and the highlight arriving on it)
   shows first and the title last as the group opens, and the other way round
   as it closes. */
.collapsibleInner {
  min-height: 0;
  align-self: end;
}

.group-collapse-enter-active,
.group-collapse-leave-active {
  transition:
    grid-template-rows var(--duration-slow) var(--ease-out),
    margin var(--duration-slow) var(--ease-out),
    opacity var(--duration-base) var(--ease-out);
}

.group-collapse-enter-active,
.group-collapse-leave-active {
  overflow: hidden;
}

.group-collapse-enter-from,
.group-collapse-leave-to {
  grid-template-rows: 0fr;
  margin-top: 0;
  margin-bottom: 0;
  opacity: 0;
}

.groupTitle {
  margin-bottom: 0.35rem;
  font-size: var(--text-footnote);
  font-weight: 600;
  color: var(--text-3);
  /* Lines up with the icon glyphs below (~4px inside their box). */
  padding-left: 0.75rem;
}
</style>
