<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'
import PostFeed from '@/components/PostFeed.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import { useAuthStore } from '@/stores/auth'
import { useSubscriptionsStore } from '@/stores/subscriptions'
import {
  getSingleQueryValue,
  getTimePeriod,
  sortOptions,
  timePeriodOptions,
  type FeedSort,
} from '@/utils/feedQuery'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const subscriptionsStore = useSubscriptionsStore()

// `/` keeps a clean URL, so a missing or unknown sort means New.
const sort = computed<FeedSort>(() =>
  getSingleQueryValue(route.query.sort) === 'top' ? 'top' : 'new',
)
const t = computed(() => getSingleQueryValue(route.query.t))
const selectedTimePeriod = computed(() => (typeof t.value === 'string' ? t.value : 'day'))

const feedParams = computed(() => {
  const params: Record<string, string | number> = { sort: sort.value, subscribed: 'true' }

  if (sort.value === 'top') {
    params.time_period = getTimePeriod(selectedTimePeriod.value)
  }

  return params
})

const emptyText = computed(() =>
  subscriptionsStore.hasLoaded && subscriptionsStore.moons.length === 0
    ? "You haven't subscribed to any moons yet. Subscribe to a moon to see its posts here."
    : 'Hmmm... empty.',
)

const onSortChange = (value: string) => {
  void router.push({
    name: 'home',
    query: value === 'top' ? { sort: 'top', t: 'day' } : {},
  })
}

const onTimePeriodChange = (value: string) => {
  void router.push({ name: 'home', query: { sort: 'top', t: value } })
}
</script>

<template>
  <main>
    <h1>Home</h1>

    <template v-if="authStore.isLoggedIn">
      <p class="description">Posts from the moons you subscribe to.</p>

      <SegmentedControl
        :model-value="sort"
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

      <PostFeed class="feed" :params="feedParams" :empty-text="emptyText" />
    </template>

    <template v-else>
      <p class="description">
        Log in to see posts from the moons you subscribe to. You can log in or sign up from the
        account card at the bottom of the sidebar.
      </p>

      <RouterLink class="linkButton" :to="{ name: 'all', query: { sort: 'top', t: 'day' } }">
        Browse top posts
      </RouterLink>
    </template>
  </main>
</template>

<style scoped>
main {
  width: 40rem;
}

h1 {
  margin-bottom: 0.5rem;
}

.description {
  color: var(--text-2);
  margin-bottom: 1.5rem;
}

.feed {
  margin-top: 2rem;
}

.linkButton {
  display: inline-block;
  color: var(--text-2);
  background: var(--bg-2);
  padding: 0.5rem 0.9rem;
  border-radius: 10px;
  text-decoration: none;
}

.linkButton:hover {
  background: var(--bg-3);
}
</style>
