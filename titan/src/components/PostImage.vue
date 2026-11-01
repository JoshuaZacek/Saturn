<script setup lang="ts">
import { computed, onMounted, ref, useTemplateRef } from 'vue'

// Used before an image loads when the API doesn't know its size (older posts).
const FALLBACK_RATIO = 4 / 3
// Taller images stop here and sit centred in a quiet frame (fill) instead.
const MAX_HEIGHT = {
  preview: '30rem',
  full: 'min(40rem, 75vh)',
}

const props = defineProps<{
  src: string
  alt: string
  // Pixel size from the API (`image_width` / `image_height`); null if unknown.
  width?: number | null
  height?: number | null
  // Images span the column at their natural ratio, never enlarged past their
  // own size; past the mode's MAX_HEIGHT (preview: feed cards, full: the post
  // page) they're shown whole inside the frame.
  mode: 'preview' | 'full'
}>()

const status = ref<'loading' | 'loaded' | 'error'>('loading')
const naturalSize = ref<{ width: number; height: number } | null>(null)
const image = useTemplateRef<HTMLImageElement>('image')

const size = computed(() => {
  if (props.width && props.height) {
    return { width: props.width, height: props.height }
  }

  return naturalSize.value
})

const ratio = computed(() => (size.value ? size.value.width / size.value.height : FALLBACK_RATIO))

// The frame is the image's final box, so nothing moves when the image arrives:
// as wide as the column (or the image, if smaller), at the image's ratio, up to
// the mode's height.
const frameStyle = computed(() => ({
  width: size.value ? `min(100%, ${size.value.width}px)` : '100%',
  aspectRatio: String(ratio.value),
  maxHeight: MAX_HEIGHT[props.mode],
}))

const onLoad = () => {
  const element = image.value
  if (element?.naturalWidth && element.naturalHeight) {
    naturalSize.value = { width: element.naturalWidth, height: element.naturalHeight }
  }

  status.value = 'loaded'
}

const onError = () => {
  status.value = 'error'
}

// A cached image can finish before the listeners are attached.
onMounted(() => {
  if (image.value?.complete && image.value.naturalWidth > 0) {
    onLoad()
  }
})
</script>

<template>
  <div class="postImage" :class="status" :style="frameStyle" :aria-busy="status === 'loading'">
    <img
      v-show="status !== 'error'"
      ref="image"
      loading="lazy"
      :src="src"
      :alt="alt"
      @load="onLoad"
      @error="onError"
    />
    <p v-if="status === 'error'" class="errorText">Image couldn't be loaded</p>
  </div>
</template>

<style scoped>
.postImage {
  position: relative;
  max-width: 100%;
  overflow: hidden;
  border-radius: var(--radius-md);
  /* Shows around images taller than the frame, and while one loads. */
  background-color: color-mix(in srgb, var(--text-1) 4%, var(--surface));
}

/* An inner hairline, so light images keep an edge against the card. */
.postImage::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: 1;
  border-radius: inherit;
  box-shadow: inset 0 0 0 1px var(--separator);
  pointer-events: none;
}

.postImage.loading::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    90deg,
    transparent 0%,
    color-mix(in srgb, var(--bg-sub) 60%, transparent) 50%,
    transparent 100%
  );
  transform: translateX(-100%);
  animation: shimmer 1.4s ease-in-out infinite;
}

@keyframes shimmer {
  to {
    transform: translateX(100%);
  }
}

@media (prefers-reduced-motion: reduce) {
  .postImage.loading::after {
    animation: none;
    transform: none;
    opacity: 0.4;
  }
}

img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: contain;
  opacity: 0;
  transition: opacity var(--duration-slow) var(--ease-out);
}

.loaded img {
  opacity: 1;
}

.errorText {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem;
  font-size: 0.9rem;
  text-align: center;
  color: var(--text-2);
}
</style>
