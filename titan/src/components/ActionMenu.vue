<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref, watch, type Component } from 'vue'
import DotsThreeIcon from '@/components/icons/DotsThreeIcon.vue'
import SubmitButton from '@/components/SubmitButton.vue'

export type ActionMenuItem = {
  value: string
  label: string
  icon?: Component
  danger?: boolean
  // Asks first: the menu turns into a short confirmation in place.
  confirm?: { title: string; message?: string; action: string }
}

const props = defineProps<{
  label: string
  items: ActionMenuItem[]
  // The chosen action is running; the confirm button shows a spinner.
  busy?: boolean
}>()

const emit = defineEmits<{
  select: [value: string]
}>()

const isOpen = ref(false)
const confirming = ref<ActionMenuItem | null>(null)
const root = ref<HTMLElement | null>(null)
const trigger = ref<HTMLButtonElement | null>(null)
const panel = ref<HTMLElement | null>(null)
const panelId = `action-menu-${Math.random().toString(36).slice(2)}`

const menuItems = () =>
  Array.from(panel.value?.querySelectorAll<HTMLElement>('[role="menuitem"]') ?? [])

const focusItem = (index: number) => {
  const list = menuItems()
  if (list.length > 0) {
    list[(index + list.length) % list.length]?.focus()
  }
}

const open = async () => {
  confirming.value = null
  isOpen.value = true
  await nextTick()
  focusItem(0)
}

const close = (returnFocus = true) => {
  isOpen.value = false
  confirming.value = null
  if (returnFocus) {
    trigger.value?.focus()
  }
}

const toggle = () => (isOpen.value ? close() : void open())

const choose = async (item: ActionMenuItem) => {
  if (item.confirm) {
    confirming.value = item
    await nextTick()
    // The safe choice takes focus.
    panel.value?.querySelector<HTMLElement>('.cancelAction')?.focus()
    return
  }

  emit('select', item.value)
  close()
}

const confirmChoice = () => {
  if (confirming.value) {
    emit('select', confirming.value.value)
  }
}

const onMenuKeydown = (event: KeyboardEvent) => {
  const list = menuItems()
  const index = list.indexOf(document.activeElement as HTMLElement)

  if (event.key === 'ArrowDown') {
    focusItem(index + 1)
  } else if (event.key === 'ArrowUp') {
    focusItem(index - 1)
  } else if (event.key === 'Home') {
    focusItem(0)
  } else if (event.key === 'End') {
    focusItem(list.length - 1)
  } else {
    return
  }

  event.preventDefault()
}

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape' && isOpen.value && !props.busy) {
    event.preventDefault()
    event.stopPropagation()
    close()
  }
}

const onDocumentPointerDown = (event: PointerEvent) => {
  if (isOpen.value && !props.busy && !root.value?.contains(event.target as Node)) {
    close(false)
  }
}

// Once the action has finished (or failed), the menu has done its job.
watch(
  () => props.busy,
  (busy, wasBusy) => {
    if (wasBusy && !busy) {
      close(false)
    }
  },
)

onMounted(() => document.addEventListener('pointerdown', onDocumentPointerDown))
onBeforeUnmount(() => document.removeEventListener('pointerdown', onDocumentPointerDown))
</script>

<template>
  <div ref="root" class="actionMenu" @keydown="onKeydown">
    <button
      ref="trigger"
      class="trigger"
      type="button"
      :aria-label="label"
      aria-haspopup="menu"
      :aria-expanded="isOpen"
      :aria-controls="isOpen ? panelId : undefined"
      @click="toggle"
    >
      <slot name="trigger">
        <DotsThreeIcon :size="20" />
      </slot>
    </button>

    <Transition name="action-menu">
      <div v-if="isOpen" :id="panelId" ref="panel" class="panel">
        <div v-if="!confirming" role="menu" :aria-label="label" @keydown="onMenuKeydown">
          <button
            v-for="item in items"
            :key="item.value"
            class="item"
            :class="{ danger: item.danger }"
            type="button"
            role="menuitem"
            tabindex="-1"
            @click="choose(item)"
          >
            <component :is="item.icon" v-if="item.icon" :size="18" />
            <span>{{ item.label }}</span>
          </button>
        </div>

        <div
          v-else-if="confirming.confirm"
          class="confirm"
          role="alertdialog"
          :aria-labelledby="`${panelId}-title`"
          :aria-describedby="confirming.confirm.message ? `${panelId}-message` : undefined"
        >
          <p :id="`${panelId}-title`" class="confirmTitle">{{ confirming.confirm.title }}</p>
          <p v-if="confirming.confirm.message" :id="`${panelId}-message`" class="confirmMessage">
            {{ confirming.confirm.message }}
          </p>
          <div class="confirmActions">
            <SubmitButton
              class="cancelAction"
              variant="secondary"
              size="sm"
              :disabled="busy"
              @click="close()"
            >
              Cancel
            </SubmitButton>
            <SubmitButton variant="danger" size="sm" :loading="busy" @click="confirmChoice">
              {{ confirming.confirm.action }}
            </SubmitButton>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.actionMenu {
  position: relative;
  /* Above a card's full-size link. */
  z-index: 2;
  display: inline-flex;
}

.trigger {
  display: inline-grid;
  place-items: center;
  width: 1.75rem;
  height: 1.75rem;
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  color: var(--text-2);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .trigger:hover {
    background-color: var(--fill-hover);
    color: var(--text-1);
  }
}

.trigger:active,
.trigger[aria-expanded='true'] {
  background-color: var(--fill-pressed);
  color: var(--text-1);
}

@media (pointer: coarse) {
  .trigger {
    width: 2.25rem;
    height: 2.25rem;
    margin: -0.25rem;
  }
}

.panel {
  position: absolute;
  top: calc(100% + 0.35rem);
  right: 0;
  z-index: 30;
  min-width: 11rem;
  padding: 0.25rem;
  border-radius: var(--radius-md);
  background-color: var(--surface-raised);
  box-shadow: var(--shadow-lg);
  transform-origin: top right;
}

.item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  height: 2.125rem;
  padding: 0 0.6rem;
  border: none;
  border-radius: var(--radius-xs);
  background: none;
  font-size: var(--text-subhead);
  text-align: left;
  white-space: nowrap;
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.item:focus-visible {
  outline: none;
  background-color: var(--fill-hover);
}

@media (hover: hover) {
  .item:hover {
    background-color: var(--fill-hover);
  }
}

.item.danger {
  color: var(--danger);
}

.confirm {
  width: 15.5rem;
  padding: 0.55rem 0.55rem 0.45rem;
}

.confirmTitle {
  font-size: var(--text-subhead);
  font-weight: 600;
}

.confirmMessage {
  margin-top: 0.2rem;
  font-size: var(--text-footnote);
  line-height: 1.4;
  color: var(--text-2);
}

.confirmActions {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
  margin-top: 0.8rem;
}

.action-menu-enter-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.action-menu-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-in-out),
    transform var(--duration-fast) var(--ease-in-out);
}

.action-menu-enter-from,
.action-menu-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.97);
}
</style>
