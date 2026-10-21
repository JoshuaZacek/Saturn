import { onBeforeUnmount, watch, type Ref } from 'vue'

// How far below the visible area the sentinel can be before the next page loads.
const LOAD_AHEAD_PX = 400

// Pages scroll inside `.page-content`, not the window, so the observer has to
// use the nearest scrolling ancestor as its root.
const getScrollParent = (element: HTMLElement) => {
  let node = element.parentElement

  while (node) {
    const { overflowY } = getComputedStyle(node)
    if (overflowY === 'auto' || overflowY === 'scroll') {
      return node
    }

    node = node.parentElement
  }

  return null
}

const isWithinReach = (element: HTMLElement) => {
  const scrollParent = getScrollParent(element)
  const visibleBottom = scrollParent
    ? scrollParent.getBoundingClientRect().bottom
    : window.innerHeight

  return element.getBoundingClientRect().top <= visibleBottom + LOAD_AHEAD_PX
}

// Calls `onReach` whenever `sentinel` scrolls into reach and `canLoad()` is true.
// When `canLoad()` becomes true again (a page finished loading) and the
// sentinel is still in reach (the page was too short to fill the screen), it
// calls `onReach` again, so short pages keep loading until the screen is full.
export const useInfiniteScroll = (
  sentinel: Readonly<Ref<HTMLElement | null>>,
  onReach: () => void,
  canLoad: () => boolean,
) => {
  let observer: IntersectionObserver | null = null

  const disconnect = () => {
    observer?.disconnect()
    observer = null
  }

  watch(
    sentinel,
    (element) => {
      disconnect()

      if (!element) {
        return
      }

      observer = new IntersectionObserver(
        (entries) => {
          if (entries.some((entry) => entry.isIntersecting) && canLoad()) {
            onReach()
          }
        },
        {
          root: getScrollParent(element),
          rootMargin: `0px 0px ${LOAD_AHEAD_PX}px 0px`,
        },
      )
      observer.observe(element)
    },
    { immediate: true, flush: 'post' },
  )

  watch(
    canLoad,
    (ready) => {
      const element = sentinel.value
      if (ready && element && isWithinReach(element)) {
        onReach()
      }
    },
    { flush: 'post' },
  )

  onBeforeUnmount(disconnect)
}
