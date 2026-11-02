<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import NotificationList from '@/components/NotificationList.vue'
import NotificationOptions from '@/components/NotificationOptions.vue'
import SheetDialog from '@/components/SheetDialog.vue'
import BellIcon from '@/components/icons/BellIcon.vue'
import { useNotificationsStore } from '@/stores/notifications'
import { useUIStore } from '@/stores/ui'

// The bell, beside Create (+) in the sidebar and the phone top bar, with the
// unread count. It opens the list: a popover on wide screens (on top of the
// page, since the sidebar would clip it), a sheet on small ones.
const EDGE_PX = 8
const GAP_PX = 6

const notifications = useNotificationsStore()
const uiStore = useUIStore()
const route = useRoute()

const isOpen = ref(false)
const trigger = ref<HTMLButtonElement | null>(null)
const panel = ref<HTMLElement | null>(null)
const panelId = `notifications-${Math.random().toString(36).slice(2)}`
const position = ref({ top: 0, left: 0, maxHeight: 0 })

const label = computed(() =>
  notifications.unreadCount > 0
    ? `Notifications, ${notifications.unreadCount} new`
    : 'Notifications',
)

const placePanel = () => {
  const rect = trigger.value?.getBoundingClientRect()
  if (!rect) {
    return
  }

  const width = Math.min(window.innerWidth - EDGE_PX * 2, 24 * 16)
  const top = rect.bottom + GAP_PX
  position.value = {
    top,
    // Lines up with the bell's left edge, so it opens out over the page.
    left: Math.max(EDGE_PX, Math.min(rect.left, window.innerWidth - EDGE_PX - width)),
    maxHeight: Math.min(window.innerHeight - top - EDGE_PX * 2, 36 * 16),
  }
}

const open = async () => {
  isOpen.value = true
  notifications.openPanel()
  if (!uiStore.isCompactLayout) {
    placePanel()
    await nextTick()
    panel.value?.focus()
  }
}

const close = (returnFocus = true) => {
  if (!isOpen.value) {
    return
  }

  isOpen.value = false
  notifications.closePanel()
  if (returnFocus && !uiStore.isCompactLayout) {
    trigger.value?.focus()
  }
}

const toggle = () => (isOpen.value ? close() : void open())

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape' && isOpen.value && !uiStore.isCompactLayout) {
    event.preventDefault()
    close()
  }
}

const onDocumentPointerDown = (event: PointerEvent) => {
  const target = event.target as Node
  if (
    isOpen.value &&
    !uiStore.isCompactLayout &&
    !panel.value?.contains(target) &&
    !trigger.value?.contains(target)
  ) {
    close(false)
  }
}

const onResize = () => {
  if (isOpen.value && !uiStore.isCompactLayout) {
    placePanel()
  }
}

// Going somewhere (a notification, or anything else) closes it.
watch(
  () => route.fullPath,
  () => close(false),
)
watch(
  () => uiStore.isCompactLayout,
  () => close(false),
)

onMounted(() => {
  document.addEventListener('pointerdown', onDocumentPointerDown)
  window.addEventListener('resize', onResize)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', onDocumentPointerDown)
  window.removeEventListener('resize', onResize)
  close(false)
})
</script>

<template>
  <button
    ref="trigger"
    class="trigger bellTrigger"
    type="button"
    :aria-label="label"
    aria-haspopup="dialog"
    :aria-expanded="isOpen"
    :aria-controls="isOpen ? panelId : undefined"
    @click="toggle"
  >
    <BellIcon :size="24" :filled="isOpen" />
    <Transition name="badge">
      <span v-if="notifications.unreadCount > 0" class="badge" aria-hidden="true">
        {{ notifications.badgeLabel }}
      </span>
    </Transition>
  </button>

  <Teleport v-if="!uiStore.isCompactLayout" to="body">
    <Transition name="notifications-panel">
      <div
        v-if="isOpen"
        :id="panelId"
        ref="panel"
        class="notificationsPanel"
        role="dialog"
        aria-label="Notifications"
        tabindex="-1"
        :style="{
          top: `${position.top}px`,
          left: `${position.left}px`,
          maxHeight: `${position.maxHeight}px`,
        }"
        @keydown="onKeydown"
      >
        <div class="panelHeader">
          <h2 class="panelTitle">Notifications</h2>
          <NotificationOptions />
        </div>
        <div class="panelBody">
          <NotificationList @navigate="close(false)" />
        </div>
      </div>
    </Transition>
  </Teleport>

  <SheetDialog v-else :id="panelId" :open="isOpen" label="Notifications" @close="close(false)">
    <template #header>
      <div class="sheetHeading">
        <h2 class="sheetTitle">Notifications</h2>
        <NotificationOptions />
      </div>
    </template>
    <div class="sheetBody">
      <NotificationList @navigate="close(false)" />
    </div>
  </SheetDialog>
</template>

<style scoped>
/* The same round button as Create (+) beside it. */
.bellTrigger {
  position: relative;
  display: inline-grid;
  place-items: center;
  width: var(--control-md);
  height: var(--control-md);
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  color: var(--text-1);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .bellTrigger:hover {
    background-color: var(--fill-hover);
  }
}

.bellTrigger:active,
.bellTrigger[aria-expanded='true'] {
  background-color: var(--fill-pressed);
}

.bellTrigger:focus-visible {
  outline: none;
  box-shadow: var(--focus-ring);
}

.badge {
  position: absolute;
  top: 0;
  right: -0.15rem;
  min-width: 1.15rem;
  height: 1.15rem;
  padding: 0 0.3rem;
  border-radius: var(--radius-full);
  /* A ring in the bar's colour, so it reads as sitting on the bell. */
  box-shadow: 0 0 0 2px var(--bg-1);
  background-color: var(--accent-fill);
  color: var(--accent-text);
  font-size: 0.6875rem;
  font-weight: 700;
  line-height: 1.15rem;
  text-align: center;
  font-variant-numeric: tabular-nums;
  pointer-events: none;
}

.badge-enter-active,
.badge-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.badge-enter-from,
.badge-leave-to {
  opacity: 0;
  transform: scale(0.5);
}

.notificationsPanel {
  position: fixed;
  z-index: 40;
  display: flex;
  flex-direction: column;
  width: min(24rem, calc(100vw - 1rem));
  border-radius: var(--radius-lg);
  background-color: var(--surface-raised);
  box-shadow: var(--shadow-lg);
  color: var(--text-1);
  overflow: hidden;
  transform-origin: top left;
}

.notificationsPanel:focus {
  outline: none;
}

.panelHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  min-height: 2.75rem;
  padding: 0.5rem 0.6rem 0.25rem 1rem;
}

.panelTitle {
  font-size: var(--text-body);
  font-weight: 600;
  letter-spacing: var(--tracking-snug);
}

.panelBody {
  min-height: 0;
  padding: 0 0.35rem 0.35rem;
  overflow-y: auto;
  overscroll-behavior: contain;
}

.sheetHeading {
  display: flex;
  flex: 1;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
}

.sheetTitle {
  font-size: var(--text-title-3);
  font-weight: 600;
  letter-spacing: var(--tracking-snug);
}

.sheetBody {
  max-height: min(65vh, 36rem);
  margin: -0.5rem -1rem -0.75rem;
  overflow-y: auto;
  overscroll-behavior: contain;
}

.notifications-panel-enter-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.notifications-panel-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-in-out),
    transform var(--duration-fast) var(--ease-in-out);
}

.notifications-panel-enter-from,
.notifications-panel-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.97);
}
</style>
