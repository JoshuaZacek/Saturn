<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
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
  }

  return ''
})

const isNotFoundPage = computed(() => route.name === 'not-found')
const isHomePage = computed(() => route.name === 'home')
const isTopPage = computed(
  () => route.name === 'all' && sortQuery.value === 'top' && isCorrectTimePeriod(tQuery.value),
)
const isNewPage = computed(() => route.name === 'all' && sortQuery.value === 'new')

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

onMounted(() => {
  uiStore.initSidebarWidth()
})

onBeforeUnmount(() => {
  stopResizing()
})
</script>

<template>
  <aside
    class="sidebar"
    :class="{ resizing: isResizing }"
    :style="{ width: `${uiStore.sidebarWidthPx}px` }"
  >
    <div class="topBar">
      <router-link to="/">
        <img class="logo" width="50" height="50" src="/logo.png" alt="Logo" />
      </router-link>

      <CreateActionsSelect />
    </div>

    <div v-if="!isHomePage && !isTopPage && !isNewPage && !isNotFoundPage" class="feedsGroup">
      <p class="groupTitle">Currently Viewing</p>
      <FeedButton :label="currentTitle" :active="true" />
    </div>

    <div class="feedsGroup">
      <p class="groupTitle">Feeds</p>
      <FeedButton label="Home" :icon="HomeIcon" :active="isHomePage" @click="goToHome" />
      <FeedButton label="Top" :icon="TopIcon" :active="isTopPage" @click="goToTop" />
      <FeedButton label="New" :icon="NewIcon" :active="isNewPage" @click="goToNew" />
    </div>

    <AccountCard />

    <button
      class="resize-handle"
      type="button"
      aria-label="Resize sidebar"
      @pointerdown="startResizing"
      tabindex="-1"
    />
  </aside>
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
}

ul {
  padding-left: 1rem;
}

.feedsGroup {
  margin-top: 2rem;
}

.groupTitle {
  font-size: 0.75rem;
  text-transform: uppercase;
  color: var(--text-2);
  margin-bottom: 0.5rem;
}
</style>
