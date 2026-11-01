<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import FeedEmptyState from '@/components/FeedEmptyState.vue'
import FeedToolbar from '@/components/FeedToolbar.vue'
import PageHeader from '@/components/PageHeader.vue'
import PostFeed from '@/components/PostFeed.vue'
import { getSingleQueryValue, getTimePeriod, type FeedSort } from '@/utils/feedQuery'

const route = useRoute()
const router = useRouter()

// The router only lets `sort=new` or `sort=top` with a valid `t` through.
const sort = computed<FeedSort>(() =>
  getSingleQueryValue(route.query.sort) === 'new' ? 'new' : 'top',
)
const t = computed(() => getSingleQueryValue(route.query.t))
const selectedTimePeriod = computed(() => (typeof t.value === 'string' ? t.value : 'day'))

const feedParams = computed(() => {
  const params: Record<string, string | number> = { sort: sort.value }

  if (sort.value === 'top') {
    params.time_period = getTimePeriod(selectedTimePeriod.value)
  }

  return params
})

const onSortChange = (value: FeedSort) => {
  void router.push({
    name: 'all',
    query: value === 'top' ? { sort: 'top', t: 'day' } : { sort: 'new' },
  })
}

const onTimePeriodChange = (value: string) => {
  void router.push({ name: 'all', query: { ...route.query, sort: 'top', t: value } })
}
</script>

<template>
  <main class="feedPage">
    <PageHeader title="All posts">
      <FeedToolbar
        :sort="sort"
        :time-period="selectedTimePeriod"
        @update:sort="onSortChange"
        @update:time-period="onTimePeriodChange"
      />
    </PageHeader>

    <PostFeed :params="feedParams">
      <template #empty>
        <FeedEmptyState :sort="sort" :time-period="selectedTimePeriod" />
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
