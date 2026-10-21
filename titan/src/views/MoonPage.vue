<template>
  <div class="moonPage">
    <!-- A solid colour for now; moon admins will be able to pick a banner image later. -->
    <header class="banner">
      <div class="bannerContent">
        <div class="titleBlock">
          <h1>/{{ moonName }}</h1>

          <!-- Kept in the layout while loading so the banner doesn't change height. -->
          <div class="moonStats" :class="{ pending: !moon }" :aria-hidden="!moon">
            <span class="stat">
              <UsersIcon :size="20" />
              <span>{{ subscriberText }}</span>
            </span>
            <span class="stat age" :title="createdAtText">
              <ClockIcon :size="20" />
              <span>{{ ageText }}</span>
            </span>
          </div>
        </div>

        <div v-if="moon" class="headerActions">
          <SubmitButton
            :variant="moon.subscribed ? 'secondary' : 'default'"
            :icon="subscribeIcon"
            :class="{ offerUnsubscribe: showUnsubscribe }"
            :aria-pressed="moon.subscribed"
            :disabled="isUpdatingSubscription"
            @click="toggleSubscription"
            @pointerenter="isPointerOverSubscribe = true"
            @pointerleave="onSubscribePointerLeave"
            @focus="onSubscribeFocus"
            @blur="isSubscribeKeyboardFocused = false"
          >
            <template v-if="!moon.subscribed">Subscribe</template>
            <!-- Both labels share one grid cell, so swapping them doesn't resize the button. -->
            <span v-else class="toggleLabels">
              <span :class="{ hidden: showUnsubscribe }">Subscribed</span>
              <span :class="{ hidden: !showUnsubscribe }">Unsubscribe</span>
            </span>
          </SubmitButton>
          <SubmitButton
            variant="secondary"
            :icon="CreatePostIcon"
            @click="router.push({ name: 'create-post', query: { moon: moon.name } })"
          >
            Create post
          </SubmitButton>
        </div>
      </div>
    </header>

    <main>
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
  </div>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import PostFeed from '@/components/PostFeed.vue'
import ClockIcon from '@/components/icons/ClockIcon.vue'
import CloseIcon from '@/components/icons/CloseIcon.vue'
import CreatePostIcon from '@/components/icons/CreatePostIcon.vue'
import PlusIcon from '@/components/icons/PlusIcon.vue'
import TickIcon from '@/components/icons/TickIcon.vue'
import UsersIcon from '@/components/icons/UsersIcon.vue'
import { notFoundLocation } from '@/router'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useSubscriptionsStore } from '@/stores/subscriptions'
import {
  getSingleQueryValue,
  getTimePeriod,
  sortOptions,
  timePeriodOptions,
  type FeedSort,
} from '@/utils/feedQuery'
import { formatCompactCount } from '@/utils/formatCount'
import { formatAge } from '@/utils/relativeTime'

type Moon = {
  id: number
  name: string
  inserted_at: string
  updated_at: string
  subscribed: boolean
  subscribers: number
}

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const subscriptionsStore = useSubscriptionsStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const moonName = computed(() => String(route.params.moon))
const sort = computed(() => getSingleQueryValue(route.query.sort) as FeedSort | undefined)
const t = computed(() => getSingleQueryValue(route.query.t))
const timePeriod = computed(() => getTimePeriod(t.value))
const selectedTimePeriod = computed(() => (typeof t.value === 'string' ? t.value : 'day'))
const moon = ref<Moon | null>(null)
const isLoadingMoon = ref(true)
const isUpdatingSubscription = ref(false)

// Placeholder text keeps the stats' height while the moon loads.
const subscriberText = computed(() => {
  if (!moon.value) {
    return 'Loading subscribers'
  }

  const count = moon.value.subscribers
  return `${formatCompactCount(count)} ${count === 1 ? 'subscriber' : 'subscribers'}`
})
const ageText = computed(() => (moon.value ? formatAge(moon.value.inserted_at) : 'Loading age'))
const createdAtText = computed(() =>
  moon.value ? `Created at ${new Date(moon.value.inserted_at).toLocaleString()}` : undefined,
)

// A subscribed moon's button reads "Subscribed" and offers "Unsubscribe" on hover
// or keyboard focus. Right after subscribing the pointer is still on the button,
// so the offer waits until it has left once.
const isPointerOverSubscribe = ref(false)
const isSubscribeKeyboardFocused = ref(false)
const isUnsubscribeOfferArmed = ref(true)
const showUnsubscribe = computed(
  () =>
    !!moon.value?.subscribed &&
    isUnsubscribeOfferArmed.value &&
    (isPointerOverSubscribe.value || isSubscribeKeyboardFocused.value),
)
const subscribeIcon = computed(() => {
  if (!moon.value?.subscribed) {
    return PlusIcon
  }

  return showUnsubscribe.value ? CloseIcon : TickIcon
})

const onSubscribePointerLeave = () => {
  isPointerOverSubscribe.value = false
  isUnsubscribeOfferArmed.value = true
}

const onSubscribeFocus = (event: FocusEvent) => {
  isSubscribeKeyboardFocused.value = (event.target as HTMLElement).matches(':focus-visible')
}

const toggleSubscription = async () => {
  const currentMoon = moon.value
  if (!currentMoon || isUpdatingSubscription.value) {
    return
  }

  if (!authStore.isLoggedIn) {
    errorBanner.show('You must be logged in to subscribe to moons.')
    return
  }

  const subscribe = !currentMoon.subscribed
  isUpdatingSubscription.value = true

  try {
    await subscriptionsStore.setSubscribed(currentMoon, subscribe)
    currentMoon.subscribed = subscribe
    currentMoon.subscribers += subscribe ? 1 : -1
    isUnsubscribeOfferArmed.value = !subscribe
  } catch {
    errorBanner.show(
      subscribe
        ? "Couldn't subscribe to this moon. Please try again."
        : "Couldn't unsubscribe from this moon. Please try again.",
    )
  } finally {
    isUpdatingSubscription.value = false
  }
}

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
      void router.replace(notFoundLocation(route))
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
.moonPage {
  width: 100%;
}

.banner {
  --banner-color: var(--bg-2);
  background-color: var(--banner-color);
  /* Inset from the sidebar and the page edges, with the same radius as post cards. */
  margin: 1rem;
  border-radius: 0.75rem;
  padding: 4rem 1.5rem;
}

/* Lines the banner's contents up with the 40rem column of posts below. */
.bannerContent {
  max-width: 40rem;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.titleBlock {
  min-width: 0;
}

h1 {
  font-size: 2.5rem;
  line-height: 1.15;
  overflow-wrap: anywhere;
  /* The font leaves ~0.15em of empty space above its capitals; pull the title up
     by that much so the visible gap at the top matches the one at the bottom. */
  margin-top: -0.15em;
}

.moonStats {
  margin-top: 0.6rem;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.3rem;
}

.moonStats.pending {
  visibility: hidden;
}

.stat {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.stat span {
  color: var(--text-2);
}

.age {
  cursor: default;
}

.headerActions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

/* The default secondary button is the banner's own colour. */
.headerActions .submitButton.secondary {
  background-color: var(--bg-sub);
  box-shadow: 0 1px 2px rgb(20 17 11 / 8%);
}

.headerActions .submitButton:not(:disabled):hover {
  filter: brightness(0.96);
}

.headerActions .submitButton.offerUnsubscribe {
  color: var(--text-error);
}

.toggleLabels {
  display: inline-grid;
}

/* Spans would otherwise take the global text colour instead of the button's. */
.toggleLabels,
.toggleLabels > span {
  color: inherit;
}

.toggleLabels > span {
  grid-area: 1 / 1;
}

.toggleLabels > .hidden {
  visibility: hidden;
}

main {
  width: 40rem;
  margin: 2rem auto 0;
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
