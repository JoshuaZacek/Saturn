import { ref } from 'vue'
import { defineStore } from 'pinia'

const SIDEBAR_WIDTH_KEY = 'sidebar-width-px'
const INITIAL_WIDTH_REM = 20
const MIN_WIDTH_REM = 15
const MAX_WIDTH_REM = 30
// At this width and below (phones, portrait tablets) the sidebar becomes a
// drawer opened from a top bar, so pages get the whole screen.
const COMPACT_LAYOUT_QUERY = '(max-width: 900px)'

export const useUIStore = defineStore('ui', () => {
  const getRootFontSizePx = () => {
    const rootFontSize = getComputedStyle(document.documentElement).fontSize
    return Number.parseFloat(rootFontSize) || 16
  }

  const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value))

  const getWidthBoundsPx = () => {
    const rootFontSizePx = getRootFontSizePx()
    return {
      min: MIN_WIDTH_REM * rootFontSizePx,
      max: MAX_WIDTH_REM * rootFontSizePx,
    }
  }

  const sidebarWidthPx = ref(INITIAL_WIDTH_REM * getRootFontSizePx())

  const initSidebarWidth = () => {
    const saved = localStorage.getItem(SIDEBAR_WIDTH_KEY)
    if (saved) {
      const savedWidth = Number.parseFloat(saved)
      const { min, max } = getWidthBoundsPx()
      sidebarWidthPx.value = clamp(savedWidth, min, max)
    }
  }

  const setSidebarWidth = (widthPx: number) => {
    const { min, max } = getWidthBoundsPx()
    const clampedWidth = clamp(widthPx, min, max)
    sidebarWidthPx.value = clampedWidth
    localStorage.setItem(SIDEBAR_WIDTH_KEY, clampedWidth.toString())
  }

  const compactLayoutMedia = window.matchMedia(COMPACT_LAYOUT_QUERY)
  const isCompactLayout = ref(compactLayoutMedia.matches)
  const isSidebarOpen = ref(false)

  compactLayoutMedia.addEventListener('change', (event) => {
    isCompactLayout.value = event.matches
    isSidebarOpen.value = false
  })

  const toggleSidebar = () => {
    isSidebarOpen.value = !isSidebarOpen.value
  }

  const closeSidebar = () => {
    isSidebarOpen.value = false
  }

  return {
    sidebarWidthPx,
    initSidebarWidth,
    setSidebarWidth,
    isCompactLayout,
    isSidebarOpen,
    toggleSidebar,
    closeSidebar,
  }
})
