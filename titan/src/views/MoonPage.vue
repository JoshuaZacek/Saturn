<template>
  <main class="moonPage">
    <EntityHeader :name="moonName" :title="`/${moonName}`" kind="moon">
      <template #meta>
        <!-- Kept in the layout while loading, so the header doesn't change height. -->
        <span class="metaItem" :class="{ pending: !moon }" :aria-hidden="!moon">
          <UsersIcon :size="16" />
          <span>{{ subscriberText }}</span>
        </span>
        <span v-if="moon" class="metaItem" :title="createdAtText">
          <ClockIcon :size="16" />
          <span>{{ createdText }}</span>
        </span>
      </template>

      <template v-if="moon" #actions>
        <SubmitButton
          :variant="moon.subscribed ? 'secondary' : 'default'"
          :icon="moon.subscribed ? undefined : PlusIcon"
          class="subscribeButton"
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
          <!-- Both icon + label pairs share one grid cell, so swapping them doesn't
               resize the button; each is centred, so the spare width splits evenly. -->
          <span v-else class="toggleLabels">
            <span class="toggleOption" :class="{ hidden: showUnsubscribe }">
              <TickIcon class="optionIcon" :size="18" />Subscribed
            </span>
            <span class="toggleOption" :class="{ hidden: !showUnsubscribe }">
              <CloseIcon class="optionIcon close" :size="18" />Unsubscribe
            </span>
          </span>
        </SubmitButton>
        <SubmitButton variant="secondary" :icon="CreatePostIcon" @click="onCreatePost">
          Create post
        </SubmitButton>
      </template>
    </EntityHeader>

    <div class="feedArea">
      <FeedToolbar
        :sort="sort ?? 'top'"
        :time-period="selectedTimePeriod"
        @update:sort="onSortChange"
        @update:time-period="onTimePeriodChange"
      />

      <PostFeed v-if="moon" class="feed" :params="feedParams" hide-moon>
        <template #empty>
          <FeedEmptyState
            :sort="sort ?? 'top'"
            :time-period="selectedTimePeriod"
            :moon-name="moon.name"
          />
        </template>
      </PostFeed>
      <div v-else-if="isLoadingMoon" class="moonLoading" aria-live="polite" aria-busy="true">
        <SpinnerLoader :size="28" fg-color="var(--text-3)" />
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import EntityHeader from '@/components/EntityHeader.vue'
import FeedEmptyState from '@/components/FeedEmptyState.vue'
import FeedToolbar from '@/components/FeedToolbar.vue'
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
import { useUIStore } from '@/stores/ui'
import { getSingleQueryValue, getTimePeriod, type FeedSort } from '@/utils/feedQuery'
import { formatCompactCount } from '@/utils/formatCount'
import { formatMonthYear } from '@/utils/relativeTime'

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
const uiStore = useUIStore()
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
const createdText = computed(() =>
  moon.value ? `Created ${formatMonthYear(moon.value.inserted_at)}` : '',
)
const createdAtText = computed(() =>
  moon.value ? `Created ${new Date(moon.value.inserted_at).toLocaleString()}` : undefined,
)

// Posting needs an account, so without one this opens the log-in sheet.
const onCreatePost = () => {
  if (!authStore.isLoggedIn) {
    uiStore.openAuth('login')
    return
  }

  void router.push({ name: 'create-post', query: { moon: moonName.value } })
}

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
    uiStore.openAuth('login')
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
  max-width: var(--column-width);
}

.metaItem {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.metaItem svg {
  color: var(--text-3);
}

.metaItem.pending {
  visibility: hidden;
}

.subscribeButton.offerUnsubscribe {
  color: var(--danger);
}

.subscribeButton.secondary {
  /* Matches SubmitButton's own icon layout for the subscribed state's icons. */
  padding-left: 0.75rem;
}

.toggleLabels {
  display: inline-grid;
}

.toggleOption {
  grid-area: 1 / 1;
  justify-self: center;
  display: inline-flex;
  align-items: center;
  /* Same as SubmitButton's icon gap. */
  gap: 0.4rem;
}

.toggleOption.hidden {
  visibility: hidden;
}

/* The ✕ glyph sits further inside its box than the other icons. */
.toggleLabels .optionIcon.close {
  margin: 0 -0.12rem;
}

/* The moon's posts, set apart from its header by a hairline. */
.feedArea {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--separator);
}

.feed {
  margin-top: 1.25rem;
}

.moonLoading {
  display: flex;
  justify-content: center;
  margin-top: 2.5rem;
}
</style>
