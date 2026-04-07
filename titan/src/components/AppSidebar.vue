<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUIStore } from '@/stores/ui'
import FeedButton from '@/components/FeedButton.vue'
import NewIcon from '@/components/icons/NewIcon.vue'
import SubscribedIcon from '@/components/icons/SubscribedIcon.vue'
import TopIcon from '@/components/icons/TopIcon.vue'
import { isCorrectTimePeriod } from '@/router/index.ts'

const router = useRouter()
const route = useRoute()
const uiStore = useUIStore()
const getSingleQueryValue = (value: unknown) => (Array.isArray(value) ? value[0] : value)

const sortQuery = computed(() => getSingleQueryValue(route.query.sort))
const tQuery = computed(() => getSingleQueryValue(route.query.t))

const isSubscribedPage = computed(() => route.name === 'subscribed')
const isTopPage = computed(
  () => route.name === 'all' && sortQuery.value === 'top' && isCorrectTimePeriod(tQuery.value),
)
const isNewPage = computed(() => route.name === 'all' && sortQuery.value === 'new')

const goToSubscribed = () => {
  router.push({ name: 'subscribed' })
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
    <img width="50" height="50" src="/logo.png" alt="Logo" />

    <div class="feedsGroup">
      <p class="groupTitle">Feeds</p>
      <FeedButton
        label="Subscribed"
        :icon="SubscribedIcon"
        :active="isSubscribedPage"
        @click="goToSubscribed"
      />
      <FeedButton label="Top" :icon="TopIcon" :active="isTopPage" @click="goToTop" />
      <FeedButton label="New" :icon="NewIcon" :active="isNewPage" @click="goToNew" />
    </div>

    <button
      class="resize-handle"
      type="button"
      aria-label="Resize sidebar"
      @pointerdown="startResizing"
    />
  </aside>
</template>

<style scoped>
.sidebar {
  position: relative;
  height: 100%;
  min-width: 15rem;
  max-width: 30rem;
  border-right: 1px solid var(--bg-2);
  padding: 1rem;
  user-select: none;
  overflow-y: scroll;
  overflow-x: hidden;
  flex-shrink: 0;
}

img {
  user-select: none;
  -webkit-user-drag: none;
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
