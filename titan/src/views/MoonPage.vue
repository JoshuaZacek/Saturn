<template>
  <main>
    <div class="header">
      <h1>/{{ moonName }}</h1>
      <SubmitButton
        v-if="moon"
        @click="router.push({ name: 'create-post', query: { moon: moon.name } })"
      >
        Create post
      </SubmitButton>
    </div>

    <SegmentedControl
      :model-value="sort ?? 'top'"
      :options="sortOptions"
      @update:model-value="onSortChange"
    />

    <CustomSelect
      v-if="sort === 'top'"
      label="Top time period"
      :model-value="selectedTimePeriod"
      :options="timePeriodOptions"
      @update:model-value="onTimePeriodChange"
    />

    <PostFeed v-if="moon" class="feed" :params="feedParams" />
    <div v-else-if="isLoadingMoon" class="moonLoading" aria-live="polite" aria-busy="true">
      <SpinnerLoader :size="30" fgColor="var(--text-3)" />
    </div>
  </main>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter, type LocationQueryValue } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import PostFeed from '@/components/PostFeed.vue'
import { useErrorBannerStore } from '@/stores/errorBanner'

type SortType = 'new' | 'top'
type Moon = {
  id: number
  name: string
  inserted_at: string
  updated_at: string
}

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
const errorBanner = useErrorBannerStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const moonName = computed(() => String(route.params.moon))
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
const sortOptions = [
  { label: 'Top', value: 'top' },
  { label: 'New', value: 'new' },
]
const selectedTimePeriod = computed(() => (typeof t.value === 'string' ? t.value : 'day'))
const moon = ref<Moon | null>(null)
const isLoadingMoon = ref(true)

const feedParams = computed(() => {
  const params: Record<string, string | number> = { sort: sort.value ?? 'top' }

  if (moon.value) {
    params.moon_id = moon.value.id
  }

  if (sort.value === 'top') {
    params.time_period = timePeriod.value
  }

  return params
})

const onSortChange = (value: string) => {
  if (value !== 'top' && value !== 'new') {
    return
  }

  void router.push({
    name: 'moon',
    query: {
      ...route.query,
      sort: value,
      ...(value === 'new' ? { t: undefined } : { t: 'day' }),
    },
    params: {
      moon: route.params.moon,
    },
  })
}

const onTimePeriodChange = (value: string) => {
  void router.push({
    name: 'moon',
    query: {
      ...route.query,
      sort: 'top',
      t: value,
    },
    params: {
      moon: route.params.moon,
    },
  })
}

let moonRequestId = 0

const loadMoon = async (name: string) => {
  const currentRequestId = ++moonRequestId
  moon.value = null
  isLoadingMoon.value = true

  try {
    if (!backendUrl) {
      throw new Error('VITE_BACKEND_URL is not set')
    }

    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.get<Moon>(`${base}/moon/${encodeURIComponent(name)}`)

    if (currentRequestId !== moonRequestId) {
      return
    }

    moon.value = response.data
  } catch (err) {
    if (currentRequestId !== moonRequestId) {
      return
    }

    if (axios.isAxiosError(err) && err.response?.status === 404) {
      void router.replace({ name: 'not-found' })
    } else {
      errorBanner.show("Moon couldn't be loaded. Please try again.")
    }
  } finally {
    if (currentRequestId === moonRequestId) {
      isLoadingMoon.value = false
    }
  }
}

// The component is reused when navigating between moons, so reload on param change.
watch(moonName, (name) => void loadMoon(name), { immediate: true })
</script>

<style scoped>
.header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

h1 {
  overflow-wrap: anywhere;
}

main {
  width: 40rem;
}

.feed {
  margin-top: 2rem;
}

.moonLoading {
  display: flex;
  justify-content: center;
  margin-top: 2rem;
}
</style>
