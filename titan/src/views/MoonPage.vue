<template>
  <main>
    <h1>/{{ route.params.moon }}</h1>
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

    <div v-if="posts.length > 0" class="postsContainer">
      <PostCard v-for="post in posts" :key="post.id" :post="post" />
    </div>

    <p v-if="!nextCursor && posts.length > 0">You've reached the end.</p>

    <p v-else-if="!nextCursor && posts.length == 0">Hmmm... empty.</p>
  </main>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, onBeforeMount, ref, watch } from 'vue'
import { useRoute, useRouter, type LocationQueryValue } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import PostCard from '@/components/PostCard.vue'
import type { Post, PostsResponse } from '@/types/post'

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
const sortOptions = [
  { label: 'Top', value: 'top' },
  { label: 'New', value: 'new' },
]
const selectedTimePeriod = computed(() => (typeof t.value === 'string' ? t.value : 'day'))
const nextCursor = ref<string | null>(null)
const storedPosts = ref<Post[]>([])
const moon = ref<Moon | null>(null)
const posts = computed(() => storedPosts.value)

const onSortChange = (value: string) => {
  if (value !== 'top' && value !== 'new') {
    return
  }

  void router.push({
    name: 'moon',
    query: {
      ...route.query,
      sort: value,
      ...(value === 'new' ? { t: undefined } : {}),
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

onBeforeMount(() => {
  axios
    .get(`${backendUrl}/moon/${route.params.moon}`)
    .then((res) => {
      moon.value = res.data
      fetchPosts()
    })
    .catch((err) => {
      if (err?.response?.status == 404) {
        router.replace({ name: 'not-found' })
      } else {
        alert("Moon couldn't be loaded. Please try again.")
      }
    })
})

let requestId = 0
const fetchPosts = async () => {
  storedPosts.value = []

  if (!backendUrl || (sort.value !== 'new' && sort.value !== 'top') || !moon.value) {
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
    moon_id: moon.value.id,
  }

  if (sort.value === 'top') {
    params.time_period = timePeriod.value
  }

  try {
    const response = await axios.get<PostsResponse>(endpoint, { params })

    if (currentRequestId !== requestId) {
      return
    }

    nextCursor.value = response.data.next_cursor
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

<style scoped>
h1 {
  margin-bottom: 1rem;
}

.postsContainer {
  margin-top: 2rem;
  display: grid;
  gap: 1.5rem;
}

main {
  width: 40rem;
}

p {
  color: var(--text-2);
  margin-top: 2rem;
  text-align: center;
}

main::after {
  content: '';
  display: block;
  height: 5rem;
}
</style>
