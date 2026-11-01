import { onBeforeUnmount, onMounted, readonly, ref } from 'vue'

const TICK_MS = 30_000

// The current time, refreshed every 30 seconds, so "2m ago" stays true while
// a page is open. One timer is shared by everything using it, and only runs
// while something is.
const now = ref(Date.now())
let users = 0
let timer: ReturnType<typeof setInterval> | undefined

export const useNow = () => {
  onMounted(() => {
    if (users++ === 0) {
      now.value = Date.now()
      timer = setInterval(() => (now.value = Date.now()), TICK_MS)
    }
  })

  onBeforeUnmount(() => {
    if (--users === 0) {
      clearInterval(timer)
    }
  })

  return readonly(now)
}
