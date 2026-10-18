<script setup lang="ts">
import { useTemplateRef } from 'vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import { useInfiniteScroll } from '@/composables/useInfiniteScroll'

const props = withDefaults(
  defineProps<{
    loading: boolean
    hasMore: boolean
    failed?: boolean
    empty?: boolean
    emptyText?: string
    endText?: string
    spinnerSize?: number
    spinnerBgColor?: string
  }>(),
  {
    failed: false,
    empty: false,
    emptyText: '',
    endText: '',
    spinnerSize: 30,
    spinnerBgColor: 'var(--bg-1)',
  },
)

const emit = defineEmits<{
  loadMore: []
  retry: []
}>()

const sentinel = useTemplateRef<HTMLDivElement>('sentinel')

useInfiniteScroll(
  sentinel,
  () => emit('loadMore'),
  () => props.hasMore && !props.loading && !props.failed,
)
</script>

<template>
  <div class="infiniteScrollFooter">
    <div ref="sentinel" class="sentinel" aria-hidden="true" />

    <div v-if="loading" class="status" aria-live="polite" aria-busy="true">
      <SpinnerLoader :size="spinnerSize" :bgColor="spinnerBgColor" fgColor="var(--text-3)" />
    </div>
    <button v-else-if="failed" class="retryButton" type="button" @click="emit('retry')">
      Try again
    </button>
    <p v-else-if="empty && emptyText" class="status">{{ emptyText }}</p>
    <p v-else-if="!hasMore && !empty && endText" class="status">{{ endText }}</p>
  </div>
</template>

<style scoped>
.infiniteScrollFooter {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.sentinel {
  width: 100%;
  height: 1px;
}

.status {
  display: flex;
  justify-content: center;
  color: var(--text-2);
  text-align: center;
}

.retryButton {
  border: none;
  border-radius: 10px;
  padding: 0.35rem 0.75rem;
  font-size: 0.9rem;
  background: var(--bg-2);
  cursor: pointer;
}
</style>
