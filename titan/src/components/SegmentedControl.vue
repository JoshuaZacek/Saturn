<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'

type SegmentedOption = {
  label: string
  value: string
}

const props = defineProps<{
  modelValue: string
  options: SegmentedOption[]
}>()

defineEmits<{
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

onBeforeUnmount(() => {
  if (fadeTimeout) {
    clearTimeout(fadeTimeout)
  }
})
</script>

<template>
  <div class="segmentedControl" :style="controlStyle" role="tablist" aria-label="Sort posts">
    <span class="activePill" :class="{ fading: isFading }" aria-hidden="true" />

    <button
      v-for="option in options"
      :key="option.value"
      type="button"
      class="segment"
      :class="{ active: option.value === modelValue }"
      role="tab"
      :aria-selected="option.value === modelValue"
      @click="$emit('update:modelValue', option.value)"
    >
      {{ option.label }}
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
  border-radius: 12px;
  background-color: var(--bg-2);
  margin-bottom: 1rem;
}

.activePill {
  position: absolute;
  top: 0.2rem;
  left: 0.2rem;
  width: calc((100% - 0.4rem) / var(--segments));
  height: calc(100% - 0.4rem);
  border-radius: 9px;
  background-color: var(--bg-sub);
  transform: translateX(calc(var(--active-index) * 100%));
  will-change: transform;
  opacity: 1;
  transition:
    transform 0.3s cubic-bezier(0.25, 0.1, 0.25, 1),
    opacity 0.18s ease;
}

.activePill.fading {
  opacity: 0.88;
}

.segment {
  position: relative;
  z-index: 1;
  border: none;
  background: transparent;
  border-radius: 9px;
  height: 2.2rem;
  font-size: 0.95rem;
  font-weight: 400;
  color: var(--text-2);
  cursor: pointer;
  transition: color 0.28s ease;
}

.segment.active {
  font-weight: 600;
  color: var(--text-1);
}
</style>
