<template>
  <main :class="sort">
    <h1>{{ capitalizeFirstLetter(sort) }} posts on Saturn{{ sort === 'top' ? '...' : '' }}</h1>
    <CustomSelect
      v-if="sort === 'top'"
      label="Top time period"
      :model-value="selectedTimePeriod"
      :options="timePeriodOptions"
      @update:model-value="onTimePeriodChange"
    />

    <PostFeed class="feed" :params="feedParams" />
  </main>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter, type LocationQueryValue } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'
import PostFeed from '@/components/PostFeed.vue'

type SortType = 'new' | 'top'

const capitalizeFirstLetter = (s: string | undefined) =>
  s ? s.charAt(0).toUpperCase() + s.slice(1) : ''

const getTimePeriod = (value: unknown) => {
  switch (value) {
    case 'day':
      return 86400
    case 'week':
      return 604800
    case 'month':
      return 2592000
    case 'year':
      return 31536000
    case 'all':
      return 0
    default:
      return 0
  }
}

const getSingleQueryValue = (value: LocationQueryValue | LocationQueryValue[] | undefined) =>
  Array.isArray(value) ? value[0] : value

const route = useRoute()
const router = useRouter()

const sort = computed(() => getSingleQueryValue(route.query.sort) as SortType | undefined)

const t = computed(() => getSingleQueryValue(route.query.t))
const timePeriod = computed(() => getTimePeriod(t.value))

const timePeriodOptions = [
  { label: 'Today', value: 'day' },
  { label: 'This Week', value: 'week' },
  { label: 'This Month', value: 'month' },
  { label: 'This Year', value: 'year' },
  { label: 'All Time', value: 'all' },
]

const selectedTimePeriod = computed(() => (typeof t.value === 'string' ? t.value : 'day'))

const feedParams = computed(() => {
  const params: Record<string, string | number> = { sort: sort.value ?? 'new' }

  if (sort.value === 'top') {
    params.time_period = timePeriod.value
  }

  return params
})

const onTimePeriodChange = (value: string) => {
  void router.push({
    name: 'all',
    query: {
      ...route.query,
      sort: 'top',
      t: value,
    },
  })
}
</script>

<style scoped>
h1 {
  margin-bottom: 1.5rem;
}

.new h1 {
  margin-bottom: 0;
}

main {
  width: 40rem;
  --post-feed-gap: 2rem;
}

.feed {
  margin-top: 2rem;
}

.new .feed {
  margin-top: 1.5rem;
}
</style>
