<script setup lang="ts">
import CustomSelect from '@/components/CustomSelect.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import { sortOptions, timePeriodOptions, type FeedSort } from '@/utils/feedQuery'

// The same controls on every feed: Top | New, and for Top, the time period.
// The period menu sits after the sort control, so it can come and go without
// moving anything you might be about to click.
defineProps<{
  sort: FeedSort
  timePeriod: string
}>()

const emit = defineEmits<{
  'update:sort': [value: FeedSort]
  'update:timePeriod': [value: string]
}>()

const onSortChange = (value: string) => {
  if (value === 'top' || value === 'new') {
    emit('update:sort', value)
  }
}
</script>

<template>
  <div class="feedToolbar">
    <SegmentedControl
      size="sm"
      label="Sort posts"
      :model-value="sort"
      :options="sortOptions"
      @update:model-value="onSortChange"
    />
    <Transition name="period">
      <CustomSelect
        v-if="sort === 'top'"
        label="Top time period"
        :model-value="timePeriod"
        :options="timePeriodOptions"
        @update:model-value="emit('update:timePeriod', $event)"
      />
    </Transition>
  </div>
</template>

<style scoped>
.feedToolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}

.period-enter-active,
.period-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.period-enter-from,
.period-leave-to {
  opacity: 0;
  transform: translateX(-4px);
}
</style>
