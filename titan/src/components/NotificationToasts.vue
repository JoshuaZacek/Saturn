<script setup lang="ts">
import { onBeforeUnmount, watch } from 'vue'
import { useRouter } from 'vue-router'
import NotificationSummary from '@/components/NotificationSummary.vue'
import { useNotificationsStore } from '@/stores/notifications'
import { notificationLabel, notificationRoute, type AppNotification } from '@/utils/notifications'

// Pop-ups for notifications that arrive while the site is open: bottom right
// on wide screens, along the bottom on phones. Each leaves after a few
// seconds, but stays while the pointer or focus is on it. Choosing one goes
// to it.
const VISIBLE_MS = 6_000

defineProps<{
  compact: boolean
}>()

const notifications = useNotificationsStore()
const router = useRouter()

// Each toast's countdown: what's left of it, and when it last (re)started.
const timers = new Map<
  number,
  { timeout?: ReturnType<typeof setTimeout>; left: number; at: number }
>()

const startTimer = (id: number) => {
  const timer = timers.get(id) ?? { left: VISIBLE_MS, at: 0 }
  clearTimeout(timer.timeout)
  timer.at = Date.now()
  timer.timeout = setTimeout(() => notifications.dismissToast(id), timer.left)
  timers.set(id, timer)
}

const pauseTimer = (id: number) => {
  const timer = timers.get(id)
  if (timer) {
    clearTimeout(timer.timeout)
    timer.left = Math.max(1_500, timer.left - (Date.now() - timer.at))
  }
}

watch(
  () => notifications.toasts.map((toast) => toast.id),
  (ids) => {
    for (const id of ids) {
      if (!timers.has(id)) {
        startTimer(id)
      }
    }

    for (const [id, timer] of timers) {
      if (!ids.includes(id)) {
        clearTimeout(timer.timeout)
        timers.delete(id)
      }
    }
  },
)

onBeforeUnmount(() => {
  for (const timer of timers.values()) {
    clearTimeout(timer.timeout)
  }
})

const openNotification = (toast: AppNotification) => {
  notifications.dismissToast(toast.id)
  void router.push(notificationRoute(toast))
}
</script>

<template>
  <div class="notificationToasts" :class="{ compact }" role="status" aria-live="polite">
    <TransitionGroup name="toast">
      <div
        v-for="toast in notifications.toasts"
        :key="toast.id"
        class="toast"
        @pointerenter="pauseTimer(toast.id)"
        @pointerleave="startTimer(toast.id)"
        @focusin="pauseTimer(toast.id)"
        @focusout="startTimer(toast.id)"
      >
        <button
          class="toastOpen"
          type="button"
          :aria-label="`${notificationLabel(toast)}. Open`"
          @click="openNotification(toast)"
        >
          <NotificationSummary :notification="toast" />
        </button>
        <button
          class="dismissButton"
          type="button"
          aria-label="Dismiss"
          @click="notifications.dismissToast(toast.id)"
        >
          &times;
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.notificationToasts {
  position: fixed;
  right: 1rem;
  bottom: 1rem;
  z-index: 25;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.5rem;
  width: min(23rem, calc(100vw - 2rem));
  pointer-events: none;
}

.notificationToasts.compact {
  right: 0;
  left: 0;
  bottom: calc(0.75rem + env(safe-area-inset-bottom));
  width: auto;
  align-items: stretch;
  padding: 0 1rem;
}

.toast {
  position: relative;
  display: flex;
  width: 100%;
  border-radius: var(--radius-lg);
  background-color: var(--surface-raised);
  box-shadow: var(--shadow-lg);
  pointer-events: auto;
}

.toastOpen {
  flex: 1;
  min-width: 0;
  padding: 0.75rem 2.5rem 0.75rem 0.85rem;
  border: none;
  border-radius: inherit;
  background: none;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .toastOpen:hover {
    background-color: var(--fill-hover);
  }
}

.toastOpen:active {
  background-color: var(--fill-pressed);
}

.toastOpen:focus-visible {
  outline: none;
  box-shadow: var(--focus-ring);
}

.dismissButton {
  position: absolute;
  top: 0.4rem;
  right: 0.4rem;
  display: inline-grid;
  place-items: center;
  width: 2rem;
  height: 2rem;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  color: var(--text-2);
  font-size: 1.25rem;
  line-height: 1;
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .dismissButton:hover {
    background-color: var(--fill-hover);
  }
}

.dismissButton:active {
  background-color: var(--fill-pressed);
}

.toast-enter-active {
  transition:
    opacity var(--duration-base) var(--ease-out),
    transform var(--duration-slow) var(--ease-out);
}

.toast-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-in-out),
    transform var(--duration-fast) var(--ease-in-out);
}

.toast-move {
  transition: transform var(--duration-slow) var(--ease-out);
}

.toast-enter-from {
  opacity: 0;
  transform: translateY(12px) scale(0.98);
}

.toast-leave-to {
  opacity: 0;
  transform: scale(0.96);
}
</style>
