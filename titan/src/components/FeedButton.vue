<script setup lang="ts">
import type { Component } from 'vue'
import UserAvatar from '@/components/UserAvatar.vue'

withDefaults(
  defineProps<{
    label: string
    icon?: Component
    // A monogram (a moon's tile or a person's circle) in place of an icon.
    avatar?: { name: string; shape: 'tile' | 'circle' }
    active?: boolean
    iconSize?: number
    // Static rows only label where you are; they don't go anywhere.
    interactive?: boolean
    // What "active" means here: the page itself, or the place a page is in.
    current?: 'page' | 'location'
  }>(),
  {
    icon: undefined,
    avatar: undefined,
    iconSize: 30,
    interactive: true,
    current: 'page',
  },
)

defineEmits<{
  click: []
}>()
</script>

<template>
  <button
    class="feedButton"
    type="button"
    :class="{ active, static: !interactive }"
    :aria-current="active ? current : undefined"
    :tabindex="interactive ? undefined : -1"
    @click="interactive && $emit('click')"
  >
    <!-- Every row keeps a 30px leading slot, so all the labels line up. -->
    <span class="lead" aria-hidden="true">
      <component :is="icon" v-if="icon" :filled="active" :size="iconSize" />
      <UserAvatar v-else-if="avatar" :name="avatar.name" :shape="avatar.shape" :size="22" />
    </span>
    <span class="label">{{ label }}</span>
  </button>
</template>

<style scoped>
.feedButton {
  /* Above the sidebar's selection highlight, which sits behind the rows. */
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  height: 2.75rem;
  gap: 0.25rem;
  padding-left: 0.5rem;
  border: none;
  border-radius: var(--radius-md);
  background: none;
  font-size: 1.1rem;
  text-align: left;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.lead {
  display: inline-grid;
  place-items: center;
  flex-shrink: 0;
  width: 30px;
  height: 30px;
}

.label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.static {
  cursor: default;
}

@media (hover: hover) {
  .feedButton:not(.active):not(.static):hover {
    background-color: var(--fill-hover);
  }
}

.feedButton:not(.static):active {
  background-color: var(--fill-pressed);
}

/* The sidebar's gliding selection highlight draws the active background. */
.feedButton.active {
  font-weight: 600;
}
</style>
