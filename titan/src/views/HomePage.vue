<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import EmptyState from '@/components/EmptyState.vue'
import FeedEmptyState from '@/components/FeedEmptyState.vue'
import FeedToolbar from '@/components/FeedToolbar.vue'
import PageHeader from '@/components/PageHeader.vue'
import PostFeed from '@/components/PostFeed.vue'
import PlanetIcon from '@/components/icons/PlanetIcon.vue'
import { useAuthStore } from '@/stores/auth'
import { useSubscriptionsStore } from '@/stores/subscriptions'
import { getSingleQueryValue, getTimePeriod, type FeedSort } from '@/utils/feedQuery'

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

const hasNoSubscriptions = computed(
  () => subscriptionsStore.hasLoaded && subscriptionsStore.moons.length === 0,
)

const onSortChange = (value: FeedSort) => {
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
  <main class="feedPage">
    <PageHeader title="Home">
      <FeedToolbar
        v-if="authStore.isLoggedIn"
        :sort="sort"
        :time-period="selectedTimePeriod"
        @update:sort="onSortChange"
        @update:time-period="onTimePeriodChange"
      />
    </PageHeader>

    <!-- The router only lets logged-in users here. -->
    <PostFeed v-if="authStore.isLoggedIn" :params="feedParams">
      <template #empty>
        <EmptyState
          v-if="hasNoSubscriptions"
          :icon="PlanetIcon"
          title="Your home feed is empty"
          description="Subscribe to moons to see their posts here."
        >
          <RouterLink
            class="btn-secondary"
            :to="{ name: 'all', query: { sort: 'top', t: 'week' } }"
          >
            Browse top posts
          </RouterLink>
        </EmptyState>
        <FeedEmptyState v-else :sort="sort" :time-period="selectedTimePeriod" />
      </template>
    </PostFeed>
  </main>
</template>

<style scoped>
.feedPage {
  width: 100%;
  max-width: var(--column-width);
}
</style>
