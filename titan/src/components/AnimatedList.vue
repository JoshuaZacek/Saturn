<script setup lang="ts">
// A list whose items fade and rise into place as they're added: on first
// render, after a reload (sort change), and as infinite scroll appends pages.
// Items added together are staggered slightly; items already shown don't move.
const STAGGER_MS = 45
const MAX_STAGGERED_ITEMS = 6

let batchIndex = 0
let batchResetQueued = false

const onBeforeEnter = (el: Element) => {
  const item = el as HTMLElement
  item.style.transitionDelay = `${Math.min(batchIndex, MAX_STAGGERED_ITEMS) * STAGGER_MS}ms`
  batchIndex += 1

  // Everything inserted in the same render is one batch.
  if (!batchResetQueued) {
    batchResetQueued = true
    requestAnimationFrame(() => {
      batchIndex = 0
      batchResetQueued = false
    })
  }
}

const onAfterEnter = (el: Element) => {
  const item = el as HTMLElement
  item.style.transitionDelay = ''
}
</script>

<template>
  <TransitionGroup
    tag="div"
    name="animatedListItem"
    appear
    @before-enter="onBeforeEnter"
    @after-enter="onAfterEnter"
    @enter-cancelled="onAfterEnter"
  >
    <slot />
  </TransitionGroup>
</template>

<!-- Not scoped: the transition classes go on the slotted items. -->
<style>
.animatedListItem-enter-active {
  transition:
    opacity 280ms ease-out,
    transform 280ms ease-out;
}

.animatedListItem-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

@media (prefers-reduced-motion: reduce) {
  .animatedListItem-enter-active {
    transition: none;
  }

  .animatedListItem-enter-from {
    opacity: 1;
    transform: none;
  }
}
</style>
