<script setup lang="ts">
import { computed } from 'vue'
import { countCharacters } from '@/utils/characterCount'

const props = withDefaults(
  defineProps<{
    text: string
    max: number
    // Only show the counter once the text is this close to the limit.
    showWithin?: number
  }>(),
  {
    showWithin: 500,
  },
)

const count = computed(() => countCharacters(props.text))
const isVisible = computed(() => count.value >= props.max - props.showWithin)
</script>

<template>
  <span v-if="isVisible" class="characterCounter" :class="{ danger: count > max }">
    {{ count }} / {{ max }}
  </span>
</template>

<style scoped>
.characterCounter {
  font-size: 0.8rem;
  color: var(--text-2);
  white-space: nowrap;
}

.characterCounter.danger {
  color: var(--text-error);
}
</style>
