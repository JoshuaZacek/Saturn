<script setup lang="ts">
import { nextTick, onMounted, ref, watch } from 'vue'
import CloseIcon from '@/components/icons/CloseIcon.vue'

// A modal sheet over the page: centred on wide screens, from the bottom on
// phones. The header holds whatever the `header` slot gives it and a close
// button. `busy` keeps it open (e.g. while saving). It says when it has
// opened (to focus a field) and when it has finished closing (to reset).
// Long enough for the slower slide up on phones.
const TRANSITION_MS = 300

const props = defineProps<{
  open: boolean
  label: string
  busy?: boolean
}>()

const emit = defineEmits<{
  close: []
  opened: []
  closed: []
}>()

const dialog = ref<HTMLDialogElement | null>(null)
const isVisible = ref(false)
let closeTimer: ReturnType<typeof setTimeout> | undefined

const prefersReducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches

const show = async () => {
  const element = dialog.value
  if (!element) {
    return
  }

  clearTimeout(closeTimer)
  if (!element.open) {
    element.showModal()
  }

  await nextTick()
  // Let the closed position be drawn first, so the sheet slides (or fades) in
  // from it rather than appearing where it ends up.
  requestAnimationFrame(() =>
    requestAnimationFrame(() => {
      isVisible.value = true
    }),
  )
  emit('opened')
}

const hide = () => {
  isVisible.value = false
  clearTimeout(closeTimer)
  closeTimer = setTimeout(
    () => {
      dialog.value?.close()
      emit('closed')
    },
    prefersReducedMotion() ? 0 : TRANSITION_MS,
  )
}

const requestClose = () => {
  if (!props.busy) {
    emit('close')
  }
}

// A click on the dialog itself (not the sheet inside it) is a click on the backdrop.
const onDialogClick = (event: MouseEvent) => {
  if (event.target === dialog.value) {
    requestClose()
  }
}

watch(
  () => props.open,
  (open) => (open ? void show() : hide()),
)

onMounted(() => {
  if (props.open) {
    void show()
  }
})
</script>

<template>
  <dialog
    ref="dialog"
    class="sheetDialog"
    :class="{ visible: isVisible }"
    :aria-label="label"
    @cancel.prevent="requestClose"
    @click="onDialogClick"
  >
    <div class="sheet">
      <header class="sheetHeader">
        <slot name="header" />
        <button class="closeButton" type="button" aria-label="Close" @click="requestClose">
          <CloseIcon :size="20" />
        </button>
      </header>

      <slot />
    </div>
  </dialog>
</template>

<style scoped>
/* The dialog fills the screen invisibly; the sheet inside it is what shows. */
.sheetDialog {
  width: 100%;
  max-width: none;
  height: 100%;
  max-height: none;
  margin: 0;
  padding: 1rem;
  border: none;
  background: transparent;
  overflow: auto;
}

.sheetDialog[open] {
  display: grid;
  place-items: center;
}

.sheetDialog::backdrop {
  background-color: var(--backdrop);
  opacity: 0;
  transition: opacity var(--duration-base) var(--ease-out);
}

.sheetDialog.visible::backdrop {
  opacity: 1;
}

.sheet {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  width: min(24rem, 100%);
  padding: 1rem 1.5rem 1.5rem;
  border-radius: var(--radius-xl);
  background-color: var(--surface-raised);
  box-shadow: var(--shadow-lg);
  opacity: 0;
  transform: translateY(0.5rem) scale(0.98);
  transition:
    opacity var(--duration-base) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.visible .sheet {
  opacity: 1;
  transform: none;
}

.sheetHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  min-height: 2.5rem;
}

.closeButton {
  display: inline-grid;
  place-items: center;
  flex-shrink: 0;
  width: 2rem;
  height: 2rem;
  margin-right: -0.5rem;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  color: var(--text-2);
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .closeButton:hover {
    background-color: var(--fill-hover);
  }
}

.closeButton:active {
  background-color: var(--fill-pressed);
}

/* Phones: a sheet from the bottom of the screen. It's pinned there itself,
   rather than placed by the dialog's layout, which Safari can work out a
   frame late (showing the sheet mid-screen first). */
@media (max-width: 600px) {
  .sheetDialog {
    padding: 0;
  }

  .sheet {
    position: fixed;
    right: 0;
    bottom: 0;
    left: 0;
    width: 100%;
    max-height: calc(100dvh - 1rem);
    overflow-y: auto;
    overscroll-behavior: contain;
    padding-bottom: calc(1.5rem + env(safe-area-inset-bottom, 0px));
    border-radius: var(--radius-xl) var(--radius-xl) 0 0;
    opacity: 1;
    transform: translateY(100%);
    transition: transform var(--duration-slow) var(--ease-out);
  }

  .visible .sheet {
    transform: none;
  }
}
</style>
