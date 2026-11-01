<script setup lang="ts">
import { computed } from 'vue'

// A monogram: the name's first letter on a soft tint. People are circles and
// moons are rounded tiles, so the two read differently in lists. The hue comes
// from the name, so a moon or person keeps the same colour everywhere.
const props = withDefaults(
  defineProps<{
    name: string
    size?: number
    shape?: 'circle' | 'tile'
  }>(),
  {
    size: 32,
    shape: 'circle',
  },
)

// Hues that hold up as light tints and as dark-mode fills.
const HUES = [8, 24, 40, 88, 142, 168, 190, 210, 232, 258, 288, 330]

const hue = computed(() => {
  let hash = 0
  for (const character of props.name.toLowerCase()) {
    hash = (hash * 31 + (character.codePointAt(0) ?? 0)) >>> 0
  }
  return HUES[hash % HUES.length]
})

const initial = computed(() => (props.name.match(/[\p{L}\p{N}]/u)?.[0] ?? '?').toUpperCase())

const style = computed(() => ({
  '--avatar-hue': String(hue.value),
  '--avatar-size': `${props.size}px`,
}))
</script>

<template>
  <span class="avatar" :class="shape" :style="style" aria-hidden="true">{{ initial }}</span>
</template>

<style scoped>
.avatar {
  display: inline-grid;
  place-items: center;
  flex-shrink: 0;
  width: var(--avatar-size);
  height: var(--avatar-size);
  border-radius: var(--radius-full);
  background-color: hsl(var(--avatar-hue) var(--avatar-sat) var(--avatar-bg-l));
  color: hsl(var(--avatar-hue) var(--avatar-sat) var(--avatar-fg-l));
  font-size: calc(var(--avatar-size) * 0.46);
  font-weight: 600;
  line-height: 1;
  text-decoration: none;
  user-select: none;
}

.tile {
  border-radius: calc(var(--avatar-size) * 0.28);
}
</style>
