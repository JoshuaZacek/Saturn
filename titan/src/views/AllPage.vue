<script setup lang="ts">
import axios from 'axios'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter, type LocationQueryValue } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'

type SortType = 'new' | 'top'

interface Post {
  id: number
  title: string
}

interface PostsResponse {
  next_cursor: string | null
  posts: Post[]
}

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
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

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

const storedPosts = ref<Post[]>([])
const posts = computed(() => storedPosts.value)

let requestId = 0

const fetchPosts = async () => {
  storedPosts.value = []

  if (!backendUrl || (sort.value !== 'new' && sort.value !== 'top')) {
    if (!backendUrl) {
      alert('Sorry, something went wrong.')
    }
    return
  }

  const currentRequestId = ++requestId
  const base = backendUrl.replace(/\/$/, '')
  const endpoint = `${base}/posts`

  const params: Record<string, string | number> = {
    sort: sort.value,
    limit: 10,
  }

  if (sort.value === 'top') {
    params.time_period = timePeriod.value
  }

  try {
    const response = await axios.get<PostsResponse>(endpoint, { params })

    if (currentRequestId !== requestId) {
      return
    }

    storedPosts.value.push(...response.data.posts)
  } catch {
    if (currentRequestId !== requestId) {
      return
    }

    alert('Sorry, something went wrong.')
  }
}

watch(
  [sort, t],
  () => {
    void fetchPosts()
  },
  { immediate: true },
)
</script>

<template>
  <main>
    <h1>{{ capitalizeFirstLetter(sort) }} posts on Saturn{{ sort === 'top' ? '...' : '' }}</h1>
    <CustomSelect
      v-if="sort === 'top'"
      label="Top time period"
      :model-value="selectedTimePeriod"
      :options="timePeriodOptions"
      @update:model-value="onTimePeriodChange"
    />

    <div>
      <p v-for="post in posts" :key="post.id">
        {{ post.title }}
      </p>
    </div>
  </main>
</template>

<style scoped>
main {
  padding: 5rem 7.5rem;
}

h1 {
  margin-bottom: 1rem;
}
</style>
