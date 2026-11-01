<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAvatarStore } from '@/stores/avatars'
import { assetUrl, avatarHue, avatarInitial } from '@/utils/avatar'

// A person's or moon's picture: their uploaded image, or a monogram (the
// name's first letter on a soft tint of their colour). People are circles and
// moons are rounded tiles, so the two read differently in lists. Until the
// colour is known it's a neutral grey, which eases into the colour.
const props = withDefaults(
  defineProps<{
    name: string
    color?: string | null
    image?: string | null
    size?: number
    shape?: 'circle' | 'tile'
    // Show exactly this colour and image, even if the picture has been changed
    // since (the picture editor's preview).
    exact?: boolean
  }>(),
  {
    color: null,
    image: null,
    size: 32,
    shape: 'circle',
  },
)

const avatarStore = useAvatarStore()

// A picture changed in this session wins over what was loaded before it.
const changed = computed(() =>
  props.exact
    ? undefined
    : avatarStore.changedFor(props.shape === 'tile' ? 'moon' : 'user', props.name),
)
const color = computed(() => changed.value?.avatar_color ?? props.color)
const image = computed(() => (changed.value ? changed.value.avatar_image : props.image))

// An image that won't load falls back to the monogram.
const imageFailed = ref(false)
watch(image, () => (imageFailed.value = false))
const imageSrc = computed(() => (image.value && !imageFailed.value ? assetUrl(image.value) : null))

const hue = computed(() => avatarHue(color.value))
const initial = computed(() => avatarInitial(props.name))

const style = computed(() => ({
  '--avatar-size': `${props.size}px`,
  ...(hue.value === null ? {} : { '--avatar-hue': String(hue.value) }),
}))
</script>

<template>
  <span
    class="avatar"
    :class="[shape, { pending: hue === null && !imageSrc, hasImage: !!imageSrc }]"
    :style="style"
    aria-hidden="true"
  >
    <img
      v-if="imageSrc"
      class="avatarImage"
      :src="imageSrc"
      :width="size"
      :height="size"
      alt=""
      decoding="async"
      draggable="false"
      @error="imageFailed = true"
    />
    <template v-else>{{ initial }}</template>
  </span>
</template>

<style scoped>
.avatar {
  display: inline-grid;
  place-items: center;
  flex-shrink: 0;
  width: var(--avatar-size);
  height: var(--avatar-size);
  overflow: hidden;
  border-radius: var(--radius-full);
  background-color: hsl(var(--avatar-hue) var(--avatar-sat) var(--avatar-bg-l));
  color: hsl(var(--avatar-hue) var(--avatar-sat) var(--avatar-fg-l));
  font-size: calc(var(--avatar-size) * 0.46);
  font-weight: 600;
  line-height: 1;
  text-decoration: none;
  user-select: none;
  transition:
    background-color var(--duration-base) var(--ease-out),
    color var(--duration-base) var(--ease-out);
}

/* The colour isn't known yet (still loading). */
.avatar.pending {
  background-color: var(--fill-secondary);
  color: var(--text-3);
}

/* Behind an image while it loads, and around transparent ones. */
.avatar.hasImage {
  background-color: var(--fill-secondary);
}

.tile {
  border-radius: calc(var(--avatar-size) * 0.28);
}

.avatarImage {
  width: 100%;
  height: 100%;
  object-fit: cover;
  user-select: none;
  -webkit-user-drag: none;
}
</style>
