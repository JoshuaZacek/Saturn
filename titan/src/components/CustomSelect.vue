<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import DownIcon from './icons/DownIcon.vue'

interface SelectOption {
  label: string
  value: string
  disabled?: boolean
}

const props = withDefaults(
  defineProps<{
    modelValue?: string
    options: SelectOption[]
    placeholder?: string
    label?: string
    disabled?: boolean
  }>(),
  {
    modelValue: undefined,
    placeholder: 'Select an option',
    label: 'Select',
    disabled: false,
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const isOpen = ref(false)
const rootRef = ref<HTMLElement | null>(null)
const triggerRef = ref<HTMLButtonElement | null>(null)
const listboxRef = ref<HTMLElement | null>(null)
const activeIndex = ref(-1)
const typeaheadBuffer = ref('')
const keyboardMode = ref(false)
const shouldWaitForPointerMove = ref(false)
const openPointerPosition = ref<{ x: number; y: number } | null>(null)
let typeaheadTimer: ReturnType<typeof setTimeout> | undefined

const listboxId = `custom-select-${Math.random().toString(36).slice(2)}`
const VIEWPORT_EDGE_PADDING_PX = 16
const MAX_VISIBLE_OPTIONS = 12

const selectedIndex = computed(() =>
  props.options.findIndex((option) => option.value === props.modelValue),
)
const selectedOption = computed(() => props.options[selectedIndex.value])
const optionHeightPx = 32
const menuMaxHeightPx = computed(
  () => Math.min(props.options.length, MAX_VISIBLE_OPTIONS) * optionHeightPx,
)
const menuPosition = ref({
  left: 0,
  top: 0,
  width: 0,
})
const activeDescendantId = computed(() =>
  activeIndex.value >= 0 ? `${listboxId}-option-${activeIndex.value}` : undefined,
)
const menuStyle = computed(() => ({
  left: `${menuPosition.value.left}px`,
  top: `${menuPosition.value.top}px`,
  width: `${menuPosition.value.width}px`,
  maxHeight: `${menuMaxHeightPx.value}px`,
}))

const updateMenuPosition = () => {
  if (!isOpen.value || !triggerRef.value) {
    return
  }

  const triggerRect = triggerRef.value.getBoundingClientRect()
  const selectedRowOffset = selectedIndex.value >= 0 ? selectedIndex.value * optionHeightPx : 0
  const desiredTop = triggerRect.top - selectedRowOffset
  const desiredLeft = triggerRect.left
  const menuWidth = triggerRect.width

  const totalMenuHeight = props.options.length * optionHeightPx
  const visibleMenuHeight = Math.min(totalMenuHeight, menuMaxHeightPx.value)
  const maxTop = window.innerHeight - VIEWPORT_EDGE_PADDING_PX - visibleMenuHeight
  const maxLeft = window.innerWidth - VIEWPORT_EDGE_PADDING_PX - menuWidth

  const clampedTop = Math.max(VIEWPORT_EDGE_PADDING_PX, Math.min(desiredTop, maxTop))
  const clampedLeft = Math.min(desiredLeft, maxLeft)

  menuPosition.value = {
    left: clampedLeft,
    top: clampedTop,
    width: menuWidth,
  }
}

const onWindowReposition = () => {
  updateMenuPosition()
}

const addWindowPositionListeners = () => {
  window.addEventListener('resize', onWindowReposition)
  window.addEventListener('scroll', onWindowReposition, true)
}

const removeWindowPositionListeners = () => {
  window.removeEventListener('resize', onWindowReposition)
  window.removeEventListener('scroll', onWindowReposition, true)
}

const findNextEnabledIndex = (startIndex: number, direction: 1 | -1) => {
  if (props.options.length === 0) {
    return -1
  }

  let index = startIndex

  for (let i = 0; i < props.options.length; i += 1) {
    index = (index + direction + props.options.length) % props.options.length

    if (!props.options[index]?.disabled) {
      return index
    }
  }

  return -1
}

const findByTypeahead = (term: string) => {
  if (!term) {
    return -1
  }

  const normalizedTerm = term.toLowerCase()
  const start = activeIndex.value >= 0 ? activeIndex.value : -1

  for (let i = 1; i <= props.options.length; i += 1) {
    const index = (start + i) % props.options.length
    const option = props.options[index]

    if (!option || option.disabled) {
      continue
    }

    if (option.label.toLowerCase().startsWith(normalizedTerm)) {
      return index
    }
  }

  return -1
}

const resetTypeahead = () => {
  typeaheadBuffer.value = ''
  if (typeaheadTimer) {
    clearTimeout(typeaheadTimer)
  }
}

const applyTypeahead = (key: string) => {
  typeaheadBuffer.value += key.toLowerCase()
  if (typeaheadTimer) {
    clearTimeout(typeaheadTimer)
  }

  typeaheadTimer = setTimeout(() => {
    typeaheadBuffer.value = ''
  }, 600)

  const match = findByTypeahead(typeaheadBuffer.value)
  if (match >= 0) {
    activeIndex.value = match
  }
}

const openList = (
  origin: 'keyboard' | 'pointer' = 'pointer',
  pointerPosition?: { x: number; y: number },
) => {
  if (props.disabled || props.options.length === 0) {
    return
  }

  keyboardMode.value = origin === 'keyboard'
  isOpen.value = true

  if (origin === 'keyboard') {
    activeIndex.value = selectedIndex.value >= 0 ? selectedIndex.value : findNextEnabledIndex(-1, 1)
    shouldWaitForPointerMove.value = false
    openPointerPosition.value = null
  } else {
    activeIndex.value = selectedIndex.value >= 0 ? selectedIndex.value : -1
    shouldWaitForPointerMove.value = true
    openPointerPosition.value = pointerPosition ?? null
  }

  void nextTick(() => {
    updateMenuPosition()
    listboxRef.value?.focus()
  })
}

const closeList = (focusTrigger = true) => {
  isOpen.value = false
  resetTypeahead()
  removeWindowPositionListeners()

  if (focusTrigger) {
    void nextTick(() => {
      triggerRef.value?.focus()
    })
  }
}

const onTriggerClick = (event: MouseEvent) => {
  if (isOpen.value) {
    closeList()
    return
  }

  openList('pointer', { x: event.clientX, y: event.clientY })
}

const selectIndex = (index: number) => {
  const option = props.options[index]

  if (!option || option.disabled) {
    return
  }

  emit('update:modelValue', option.value)
  closeList()
}

const moveActive = (direction: 1 | -1) => {
  const next = findNextEnabledIndex(activeIndex.value, direction)
  if (next >= 0) {
    activeIndex.value = next
  }
}

const handleKeydown = (event: KeyboardEvent) => {
  if (props.disabled) {
    return
  }

  if (event.key === 'ArrowDown') {
    event.preventDefault()

    if (!isOpen.value) {
      openList('keyboard')
      return
    }

    keyboardMode.value = true
    moveActive(1)
    return
  }

  if (event.key === 'ArrowUp') {
    event.preventDefault()

    if (!isOpen.value) {
      openList('keyboard')
      return
    }

    keyboardMode.value = true
    moveActive(-1)
    return
  }

  if (event.key === 'Enter') {
    event.preventDefault()

    if (!isOpen.value) {
      openList('keyboard')
      return
    }

    keyboardMode.value = true
    if (activeIndex.value >= 0) {
      selectIndex(activeIndex.value)
    }
    return
  }

  if (event.key === 'Home' && isOpen.value) {
    event.preventDefault()
    keyboardMode.value = true
    const first = findNextEnabledIndex(-1, 1)
    if (first >= 0) {
      activeIndex.value = first
    }
    return
  }

  if (event.key === 'End' && isOpen.value) {
    event.preventDefault()
    keyboardMode.value = true
    const last = findNextEnabledIndex(0, -1)
    if (last >= 0) {
      activeIndex.value = last
    }
    return
  }

  if (event.key === 'Escape' && isOpen.value) {
    event.preventDefault()
    closeList()
    return
  }

  if (event.key === 'Tab' && isOpen.value) {
    closeList(false)
    return
  }

  if (event.key.length === 1 && !event.altKey && !event.ctrlKey && !event.metaKey) {
    if (!isOpen.value) {
      openList('keyboard')
    }

    keyboardMode.value = true
    applyTypeahead(event.key)
  }
}

const onTriggerKeydown = (event: KeyboardEvent) => {
  handleKeydown(event)
}

const onListboxKeydown = (event: KeyboardEvent) => {
  handleKeydown(event)
}

const onMenuPointerMove = (event: PointerEvent) => {
  if (!listboxRef.value) {
    return
  }

  if (shouldWaitForPointerMove.value) {
    const initial = openPointerPosition.value

    if (initial && event.clientX === initial.x && event.clientY === initial.y) {
      return
    }

    shouldWaitForPointerMove.value = false
  }

  const target = event.target
  if (!(target instanceof HTMLElement)) {
    return
  }

  const optionElement = target.closest<HTMLElement>('[data-option-index]')
  if (!optionElement) {
    return
  }

  const indexAttr = optionElement.dataset.optionIndex
  if (!indexAttr) {
    return
  }

  const index = Number(indexAttr)
  if (!Number.isInteger(index) || index < 0 || props.options[index]?.disabled) {
    return
  }

  keyboardMode.value = false
  activeIndex.value = index
}

const onMenuPointerLeave = () => {
  keyboardMode.value = false
  activeIndex.value = -1
}

const onClickOutside = (event: PointerEvent) => {
  if (!rootRef.value) {
    return
  }

  const target = event.target
  if (target instanceof Node && !rootRef.value.contains(target)) {
    closeList()
  }
}

document.addEventListener('pointerdown', onClickOutside)

watch(activeIndex, (index) => {
  if (!isOpen.value || index < 0 || !listboxRef.value) {
    return
  }

  // Avoid jitter when there is no real overflow to scroll.
  if (listboxRef.value.scrollHeight <= listboxRef.value.clientHeight + 1) {
    return
  }

  const optionEl = listboxRef.value.querySelector<HTMLElement>(`#${listboxId}-option-${index}`)
  optionEl?.scrollIntoView({ block: 'nearest' })
})

watch(isOpen, (open) => {
  if (open) {
    addWindowPositionListeners()
    void nextTick(() => {
      updateMenuPosition()
    })
    return
  }

  removeWindowPositionListeners()
})

watch([selectedIndex, menuMaxHeightPx], () => {
  if (!isOpen.value) {
    return
  }

  void nextTick(() => {
    updateMenuPosition()
  })
})

onBeforeUnmount(() => {
  resetTypeahead()
  document.removeEventListener('pointerdown', onClickOutside)
  removeWindowPositionListeners()
})
</script>

<template>
  <div ref="rootRef" class="customSelect" :class="{ open: isOpen, disabled }">
    <button
      ref="triggerRef"
      type="button"
      class="trigger"
      :aria-label="label"
      aria-haspopup="listbox"
      :aria-expanded="isOpen"
      :aria-controls="listboxId"
      role="combobox"
      :aria-activedescendant="activeDescendantId"
      :disabled="disabled"
      @click="onTriggerClick"
      @keydown="onTriggerKeydown"
    >
      <span class="text">{{ selectedOption?.label ?? placeholder }}</span>
      <DownIcon size="16" class="chevron" />
    </button>

    <ul
      v-if="isOpen"
      ref="listboxRef"
      :id="listboxId"
      class="menu"
      :style="menuStyle"
      role="listbox"
      :aria-label="label"
      tabindex="-1"
      @keydown="onListboxKeydown"
      @pointermove="onMenuPointerMove"
      @pointerleave="onMenuPointerLeave"
    >
      <li
        v-for="(option, index) in options"
        :key="option.value"
        :id="`${listboxId}-option-${index}`"
        :data-option-index="index"
        class="option"
        :class="{
          active: index === activeIndex,
          selected: option.value === modelValue,
          disabled: option.disabled,
        }"
        role="option"
        :aria-selected="option.value === modelValue"
        :aria-disabled="option.disabled || undefined"
        @mousedown.prevent
        @click="selectIndex(index)"
      >
        {{ option.label }}
      </li>
    </ul>
  </div>
</template>

<style scoped>
.customSelect {
  position: relative;
  width: 100%;
  max-width: 10rem;
}

.trigger {
  width: 100%;
  height: 2rem;
  border: 1px solid var(--bg-3);
  border-radius: 0.5rem;
  padding: 0 0.75rem;
  background: var(--bg-1);
  color: var(--text-1);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  font-size: 1rem;
}

.menu {
  position: fixed;
  box-sizing: content-box;
  z-index: 1000;
  list-style: none;
  border: 1px solid var(--bg-3);
  border-radius: 0.5rem;
  background: var(--bg-1);
  box-shadow: 0 10px 20px rgb(0 0 0 / 10%);
  overflow-y: auto;
}

.option {
  height: 2rem;
  padding: 0 0.75rem;
  display: flex;
  align-items: center;
  cursor: pointer;
}

.option.active {
  background: var(--bg-2);
}

.option.selected {
  font-weight: 700;
}

.option.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.disabled .trigger {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
