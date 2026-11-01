<script setup lang="ts">
import { nextTick, onBeforeUnmount, ref } from 'vue'

// A small label that appears over what it wraps when a mouse rests on it, for
// detail that doesn't need a click (a time's exact date). Touch screens can't
// hover, so it only ever adds detail. It's drawn over the whole page, so cards
// and scrolling areas can't clip it, and it hides as soon as anything scrolls.
const SHOW_DELAY_MS = 350
const GAP_PX = 6
const EDGE_PX = 8

const props = defineProps<{
  text: string
}>()

const anchor = ref<HTMLElement | null>(null)
const tip = ref<HTMLElement | null>(null)
const visible = ref(false)
const position = ref({ top: 0, left: 0, below: false })
let showTimer: ReturnType<typeof setTimeout> | undefined

const place = () => {
  const target = anchor.value?.getBoundingClientRect()
  const tooltip = tip.value
  if (!target || !tooltip) {
    return
  }

  const { width, height } = tooltip.getBoundingClientRect()
  const above = target.top - GAP_PX - height
  const below = above < EDGE_PX
  const left = target.left + target.width / 2 - width / 2

  position.value = {
    top: below ? target.bottom + GAP_PX : above,
    left: Math.min(Math.max(left, EDGE_PX), window.innerWidth - width - EDGE_PX),
    below,
  }
}

const hide = () => {
  clearTimeout(showTimer)
  visible.value = false
  window.removeEventListener('scroll', hide, true)
}

const show = async () => {
  visible.value = true
  window.addEventListener('scroll', hide, { capture: true, passive: true })
  await nextTick()
  place()
}

const onPointerEnter = (event: PointerEvent) => {
  if (event.pointerType !== 'mouse' || !props.text) {
    return
  }

  clearTimeout(showTimer)
  showTimer = setTimeout(() => void show(), SHOW_DELAY_MS)
}

onBeforeUnmount(hide)
</script>

<template>
  <span
    ref="anchor"
    class="hoverTooltipAnchor"
    @pointerenter="onPointerEnter"
    @pointerleave="hide"
    @pointerdown="hide"
  >
    <slot />
    <Teleport to="body">
      <Transition name="tooltip">
        <span
          v-if="visible"
          ref="tip"
          class="hoverTooltip"
          :class="{ below: position.below }"
          :style="{ top: `${position.top}px`, left: `${position.left}px` }"
          role="tooltip"
        >
          {{ text }}
        </span>
      </Transition>
    </Teleport>
  </span>
</template>

<style scoped>
.hoverTooltip {
  position: fixed;
  z-index: 1100;
  max-width: min(20rem, calc(100vw - 1rem));
  padding: 0.3rem 0.55rem;
  border-radius: var(--radius-sm);
  background-color: var(--tooltip-bg);
  box-shadow: var(--shadow-md);
  color: var(--tooltip-text);
  font-size: var(--text-footnote);
  font-weight: 500;
  line-height: 1.3;
  white-space: nowrap;
  pointer-events: none;
}

.tooltip-enter-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.tooltip-leave-active {
  transition: opacity 100ms var(--ease-in-out);
}

.tooltip-enter-from,
.tooltip-leave-to {
  opacity: 0;
}

/* It drifts in from the side of what it's describing. */
.tooltip-enter-from {
  transform: translateY(2px);
}

.tooltip-enter-from.below {
  transform: translateY(-2px);
}
</style>
