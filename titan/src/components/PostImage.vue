<script setup lang="ts">
import { computed, onMounted, ref, useTemplateRef } from 'vue'

// Used before an image loads when the API doesn't know its size (older posts).
const FALLBACK_RATIO = 4 / 3
const PREVIEW_HEIGHT = '10rem'

const props = defineProps<{
  src: string
  alt: string
  // Pixel size from the API (`image_width` / `image_height`); null if unknown.
  width?: number | null
  height?: number | null
  // preview: feed cards, PREVIEW_HEIGHT tall (or narrower if the card is).
  // full: the post page, natural size up to the card's width.
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

// The frame is the image's final box, so nothing moves when the image arrives.
const frameStyle = computed(() => {
  let width: string

  if (props.mode === 'preview') {
    width = `min(100%, calc(${PREVIEW_HEIGHT} * ${ratio.value}))`
  } else {
    width = size.value ? `min(100%, ${size.value.width}px)` : '100%'
  }

  return { width, aspectRatio: String(ratio.value) }
})

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
  margin-top: 0.5rem;
  max-width: 100%;
  overflow: hidden;
  border: 1px solid var(--bg-2);
  border-radius: 0.5rem;
  background-color: var(--bg-2);
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
  object-fit: cover;
  opacity: 0;
  transition: opacity 200ms ease;
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
