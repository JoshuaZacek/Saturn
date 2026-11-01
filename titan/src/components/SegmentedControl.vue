<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'

type SegmentedOption = {
  label: string
  value: string
}

const props = withDefaults(
  defineProps<{
    modelValue: string
    options: SegmentedOption[]
    label?: string
    // sm: a compact control that sizes to its labels, for toolbars.
    size?: 'sm' | 'md'
  }>(),
  {
    label: 'Sort posts',
    size: 'md',
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const activeIndex = computed(() => {
  const index = props.options.findIndex((option) => option.value === props.modelValue)
  return index >= 0 ? index : 0
})

const controlStyle = computed(() => ({
  '--segments': String(Math.max(props.options.length, 1)),
  '--active-index': String(activeIndex.value),
}))

const isFading = ref(false)
let fadeTimeout: ReturnType<typeof setTimeout> | null = null

watch(activeIndex, () => {
  isFading.value = true

  if (fadeTimeout) {
    clearTimeout(fadeTimeout)
  }

  fadeTimeout = setTimeout(() => {
    isFading.value = false
  }, 140)
})

// Tabs pattern: one tab stop, arrow keys move between segments.
const onKeydown = (event: KeyboardEvent) => {
  const count = props.options.length
  if (count === 0) {
    return
  }

  let next: number
  if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
    next = (activeIndex.value + 1) % count
  } else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
    next = (activeIndex.value - 1 + count) % count
  } else if (event.key === 'Home') {
    next = 0
  } else if (event.key === 'End') {
    next = count - 1
  } else {
    return
  }

  event.preventDefault()
  emit('update:modelValue', props.options[next]!.value)
  const buttons = (event.currentTarget as HTMLElement).querySelectorAll<HTMLButtonElement>(
    '.segment',
  )
  buttons[next]?.focus()
}

onBeforeUnmount(() => {
  if (fadeTimeout) {
    clearTimeout(fadeTimeout)
  }
})
</script>

<template>
  <div
    class="segmentedControl"
    :class="size"
    :style="controlStyle"
    role="tablist"
    :aria-label="label"
    @keydown="onKeydown"
  >
    <span class="activePill" :class="{ fading: isFading }" aria-hidden="true" />

    <button
      v-for="option in options"
      :key="option.value"
      type="button"
      class="segment"
      :class="{ active: option.value === modelValue }"
      role="tab"
      :aria-selected="option.value === modelValue"
      :tabindex="option.value === modelValue ? 0 : -1"
      @click="emit('update:modelValue', option.value)"
    >
      <span class="segmentLabel" :data-label="option.label">{{ option.label }}</span>
    </button>
  </div>
</template>

<style scoped>
.segmentedControl {
  position: relative;
  width: 100%;
  display: grid;
  grid-template-columns: repeat(var(--segments), minmax(0, 1fr));
  padding: 0.2rem;
  border-radius: var(--radius-md);
  background-color: var(--fill-secondary);
}

/* Compact: as wide as its longest label needs, every segment the same width. */
.segmentedControl.sm {
  width: auto;
  display: inline-grid;
  grid-template-columns: none;
  grid-auto-columns: 1fr;
  grid-auto-flow: column;
  padding: 2px;
  border-radius: var(--radius-sm);
}

.activePill {
  position: absolute;
  top: 0.2rem;
  left: 0.2rem;
  width: calc((100% - 0.4rem) / var(--segments));
  height: calc(100% - 0.4rem);
  border-radius: calc(var(--radius-md) - 0.2rem);
  background-color: var(--fill-raised);
  /* A soft lift only; no outline. */
  box-shadow:
    0 1px 2px rgb(var(--shadow-rgb) / 6%),
    0 2px 8px rgb(var(--shadow-rgb) / 6%);
  transform: translateX(calc(var(--active-index) * 100%));
  will-change: transform;
  opacity: 1;
  transition:
    transform var(--duration-slow) var(--ease-out),
    opacity var(--duration-fast) var(--ease-out);
}

.activePill.fading {
  opacity: 0.88;
}

.segment {
  position: relative;
  z-index: 1;
  border: none;
  background: transparent;
  border-radius: calc(var(--radius-md) - 0.2rem);
  height: calc(var(--control-md) - 0.4rem);
  padding: 0 1rem;
  font-size: var(--text-subhead);
  font-weight: 400;
  color: var(--text-2);
  cursor: pointer;
  transition: color var(--duration-base) var(--ease-out);
}

.sm .activePill {
  top: 2px;
  left: 2px;
  width: calc((100% - 4px) / var(--segments));
  height: calc(100% - 4px);
  border-radius: calc(var(--radius-sm) - 2px);
}

.sm .segment {
  height: calc(var(--control-sm) - 4px);
  min-width: 4.25rem;
  padding: 0 0.85rem;
  border-radius: calc(var(--radius-sm) - 2px);
}

/* Holds room for the label's bold (selected) width, so selecting never
   resizes anything. */
.segmentLabel {
  display: inline-grid;
}

.segmentLabel::after {
  content: attr(data-label);
  height: 0;
  overflow: hidden;
  visibility: hidden;
  font-weight: 600;
}

/* Hairlines between segments that aren't selected; they fade out either side
   of the selected one (so a two-segment control never shows one). */
.segment + .segment::before {
  content: '';
  position: absolute;
  top: 28%;
  bottom: 28%;
  left: -0.5px;
  width: 1px;
  border-radius: 1px;
  background-color: var(--separator-strong);
  transition: opacity var(--duration-fast) var(--ease-out);
}

.segment.active::before,
.segment.active + .segment::before {
  opacity: 0;
}

@media (hover: hover) {
  .segment:not(.active):hover {
    color: var(--text-1);
  }
}

.segment.active {
  font-weight: 600;
  color: var(--text-1);
}
</style>
