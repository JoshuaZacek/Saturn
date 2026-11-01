<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import EmptyState from '@/components/EmptyState.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import CreatePostIcon from '@/components/icons/CreatePostIcon.vue'
import { useAuthStore } from '@/stores/auth'
import {
  timePeriodPhrases,
  topPostsLinkLabels,
  widerTimePeriod,
  type FeedSort,
} from '@/utils/feedQuery'

// An empty feed says what's missing for the current sort and period, and offers
// the next wider period (or, in a moon with no posts, to write the first one).
const props = defineProps<{
  sort: FeedSort
  timePeriod: string
  moonName?: string
}>()

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const place = computed(() => (props.moonName ? ` in /${props.moonName}` : ''))
const phrase = computed(() =>
  props.sort === 'top' ? timePeriodPhrases[props.timePeriod] : undefined,
)

const title = computed(() =>
  phrase.value
    ? `Nothing's been posted${place.value} ${phrase.value}`
    : `No posts${place.value} yet`,
)

const wider = computed(() => (props.sort === 'top' ? widerTimePeriod(props.timePeriod) : null))
const canWriteFirstPost = computed(() => !!props.moonName && !phrase.value && authStore.isLoggedIn)

const showWider = () => {
  if (wider.value) {
    void router.push({ query: { ...route.query, sort: 'top', t: wider.value } })
  }
}
</script>

<template>
  <EmptyState :title="title">
    <SubmitButton v-if="wider" variant="secondary" size="sm" @click="showWider">
      {{ topPostsLinkLabels[wider] }}
    </SubmitButton>
    <SubmitButton
      v-else-if="canWriteFirstPost"
      size="sm"
      :icon="CreatePostIcon"
      @click="router.push({ name: 'create-post', query: { moon: moonName } })"
    >
      Write the first post
    </SubmitButton>
  </EmptyState>
</template>
