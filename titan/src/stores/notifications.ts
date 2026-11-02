import axios from 'axios'
import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { createNotificationSocket, type SocketEvent } from '@/composables/useNotificationSocket'
import type { AppNotification } from '@/utils/notifications'

export const MARK_READ_FAILED_MESSAGE =
  "Your notifications couldn't be marked as read. Please try again."
export const MARK_UNREAD_FAILED_MESSAGE =
  "That notification couldn't be marked as unread. Please try again."
export const CLEAR_FAILED_MESSAGE = "Your notifications couldn't be cleared. Please try again."
export const REMOVE_FAILED_MESSAGE = "That notification couldn't be removed. Please try again."
export const LOAD_MORE_FAILED_MESSAGE = "Older notifications couldn't be loaded. Please try again."

// How many pop-ups can be on screen at once; the oldest goes first.
const MAX_TOASTS = 3

type NotificationsPage = {
  notifications: AppNotification[]
  has_more: boolean
  unread_count: number
}

const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const apiBase = () => (backendUrl ?? '').replace(/\/$/, '')

// The logged-in person's notifications: the bell's list and unread count,
// kept live by the websocket, and the pop-ups for ones that arrive while the
// site is open. App.vue starts it on login and stops it on logout.
export const useNotificationsStore = defineStore('notifications', () => {
  const authStore = useAuthStore()
  const errorBanner = useErrorBannerStore()

  const items = ref<AppNotification[]>([])
  const unreadCount = ref(0)
  const hasMore = ref(false)
  // The list as a whole: 'error' shows "Try again" in place of it.
  const status = ref<'idle' | 'loading' | 'ready' | 'error'>('idle')
  const isLoadingMore = ref(false)
  const isClearing = ref(false)
  // The bell's list is showing; new ones go straight into it, without a pop-up.
  const isPanelOpen = ref(false)
  const toasts = ref<AppNotification[]>([])
  // A failed action, shown inside the list (it sits over the page, and on
  // phones is a modal sheet, so the page's banner would be hidden behind it).
  const actionError = ref<string | null>(null)

  let generation = 0

  // In the list while it's open; otherwise (e.g. it closed on the way to a
  // notification) in the page's banner.
  const reportError = (message: string) => {
    if (isPanelOpen.value) {
      actionError.value = message
    } else {
      errorBanner.show(message)
    }
  }

  const clearError = (message: string) => {
    if (actionError.value === message) {
      actionError.value = null
    }

    errorBanner.dismissMessage(message)
  }

  const fetch = async () => {
    const started = generation
    if (status.value !== 'ready') {
      status.value = 'loading'
    }

    try {
      const response = await axios.get<NotificationsPage>(`${apiBase()}/notifications`)
      if (started !== generation) {
        return
      }

      items.value = response.data.notifications
      hasMore.value = response.data.has_more
      unreadCount.value = response.data.unread_count
      status.value = 'ready'
    } catch {
      // A refresh that fails keeps what's already showing.
      if (started === generation && status.value !== 'ready') {
        status.value = 'error'
      }
    }
  }

  const loadMore = async () => {
    const last = items.value[items.value.length - 1]
    if (!last || isLoadingMore.value || !hasMore.value) {
      return
    }

    const started = generation
    isLoadingMore.value = true
    try {
      const response = await axios.get<NotificationsPage>(`${apiBase()}/notifications`, {
        params: { before: last.id },
      })
      if (started !== generation) {
        return
      }

      const known = new Set(items.value.map((item) => item.id))
      items.value.push(...response.data.notifications.filter((item) => !known.has(item.id)))
      hasMore.value = response.data.has_more
      clearError(LOAD_MORE_FAILED_MESSAGE)
    } catch {
      reportError(LOAD_MORE_FAILED_MESSAGE)
    } finally {
      isLoadingMore.value = false
    }
  }

  // Marks these as read here (all of them for `null`). Returns what changed,
  // to put back if the server says no. Also how another tab's change arrives,
  // so doing it twice changes nothing the second time.
  const applyRead = (ids: number[] | null) => {
    const changed: number[] = []
    items.value = items.value.map((item) => {
      if (item.read || (ids && !ids.includes(item.id))) {
        return item
      }

      changed.push(item.id)
      return { ...item, read: true }
    })

    unreadCount.value = ids === null ? 0 : Math.max(0, unreadCount.value - changed.length)
    dropToasts(ids)
    return changed
  }

  // Removes these from the list (all of them for `null`). Returns what was
  // removed and where, to put back if the server says no.
  const applyCleared = (ids: number[] | null) => {
    const removed = items.value
      .map((item, index) => ({ item, index }))
      .filter(({ item }) => ids === null || ids.includes(item.id))

    items.value = items.value.filter((item) => ids !== null && !ids.includes(item.id))
    if (ids === null) {
      unreadCount.value = 0
      hasMore.value = false
    } else {
      const unread = removed.filter(({ item }) => !item.read).length
      unreadCount.value = Math.max(0, unreadCount.value - unread)
    }

    dropToasts(ids)
    return removed
  }

  // Marks these unread again here. Returns what changed. Like applyRead,
  // doing it twice changes nothing the second time.
  const applyUnread = (ids: number[]) => {
    const changed: number[] = []
    items.value = items.value.map((item) => {
      if (!item.read || !ids.includes(item.id)) {
        return item
      }

      changed.push(item.id)
      return { ...item, read: false }
    })

    unreadCount.value += changed.length
    return changed
  }

  const dropToasts = (ids: number[] | null) => {
    toasts.value = ids === null ? [] : toasts.value.filter((toast) => !ids.includes(toast.id))
  }

  // `ids` (all of them without) are read: the badge and their dots go.
  const markRead = async (ids: number[] | null = null) => {
    const previousCount = unreadCount.value
    const changed = applyRead(ids)
    if (changed.length === 0 && (ids !== null || previousCount === 0)) {
      return
    }

    try {
      await axios.post(`${apiBase()}/notifications/read`, ids ? { ids } : {})
      clearError(MARK_READ_FAILED_MESSAGE)
    } catch {
      items.value = items.value.map((item) =>
        changed.includes(item.id) ? { ...item, read: false } : item,
      )
      unreadCount.value = previousCount
      reportError(MARK_READ_FAILED_MESSAGE)
    }
  }

  // Puts one back as new: its dot and the badge come back.
  const markUnread = async (id: number) => {
    const changed = applyUnread([id])
    if (changed.length === 0) {
      return
    }

    try {
      await axios.post(`${apiBase()}/notifications/unread`, { ids: [id] })
      clearError(MARK_UNREAD_FAILED_MESSAGE)
    } catch {
      applyRead(changed)
      reportError(MARK_UNREAD_FAILED_MESSAGE)
    }
  }

  // Removes one from the list.
  const remove = async (id: number) => {
    const previousCount = unreadCount.value
    const removed = applyCleared([id])

    try {
      await axios.delete(`${apiBase()}/notification/${id}`)
      clearError(REMOVE_FAILED_MESSAGE)
    } catch (err) {
      // Already gone (e.g. cleared in another tab) is what was wanted.
      if (axios.isAxiosError(err) && err.response?.status === 404) {
        return
      }

      for (const { item, index } of removed) {
        items.value.splice(Math.min(index, items.value.length), 0, item)
      }

      unreadCount.value = previousCount
      reportError(REMOVE_FAILED_MESSAGE)
    }
  }

  // Empties the list. Waits for the server, since it's everything at once.
  const clearAll = async () => {
    if (isClearing.value) {
      return
    }

    isClearing.value = true
    try {
      await axios.delete(`${apiBase()}/notifications`)
      applyCleared(null)
      clearError(CLEAR_FAILED_MESSAGE)
    } catch {
      reportError(CLEAR_FAILED_MESSAGE)
    } finally {
      isClearing.value = false
    }
  }

  const openPanel = () => {
    isPanelOpen.value = true
    toasts.value = []
    if (status.value !== 'ready') {
      void fetch()
    }
  }

  const closePanel = () => {
    isPanelOpen.value = false
    actionError.value = null
  }

  const dismissActionError = () => {
    actionError.value = null
  }

  const receive = (notification: AppNotification) => {
    if (items.value.some((item) => item.id === notification.id)) {
      return
    }

    items.value.unshift(notification)
    unreadCount.value += 1
    // While the list is open it's already in view.
    if (!isPanelOpen.value) {
      toasts.value = [...toasts.value, notification].slice(-MAX_TOASTS)
    }
  }

  const dismissToast = (id: number) => {
    toasts.value = toasts.value.filter((toast) => toast.id !== id)
  }

  const onEvent = ({ event, data }: SocketEvent) => {
    if (event === 'notification') {
      receive(data as AppNotification)
    } else if (event === 'notifications_read') {
      applyRead((data as { ids: number[] | null }).ids ?? null)
    } else if (event === 'notifications_unread') {
      applyUnread((data as { ids: number[] }).ids ?? [])
    } else if (event === 'notifications_cleared') {
      const { id } = data as { id: number | null }
      applyCleared(id === null ? null : [id])
    }
  }

  let connectedBefore = false
  const socket = createNotificationSocket({
    onEvent,
    // The first connection comes with start()'s fetch; a reconnection may
    // have missed some.
    onOpen: () => {
      if (connectedBefore) {
        void fetch()
      }

      connectedBefore = true
    },
    // Perhaps the session has ended; if so, this logs out (and App.vue stops this).
    onTrouble: () => void authStore.verifySession(),
  })

  const start = () => {
    connectedBefore = false
    void fetch()
    socket.connect()
  }

  const stop = () => {
    socket.disconnect()
    generation += 1
    items.value = []
    unreadCount.value = 0
    hasMore.value = false
    status.value = 'idle'
    isPanelOpen.value = false
    toasts.value = []
    actionError.value = null
  }

  const badgeLabel = computed(() => (unreadCount.value > 9 ? '9+' : String(unreadCount.value)))

  return {
    items,
    unreadCount,
    hasMore,
    status,
    isLoadingMore,
    isClearing,
    isPanelOpen,
    toasts,
    actionError,
    badgeLabel,
    fetch,
    loadMore,
    markRead,
    markUnread,
    remove,
    clearAll,
    openPanel,
    closePanel,
    dismissActionError,
    dismissToast,
    start,
    stop,
  }
})
