<template>
  <div class="voteButtons" :class="[variant, currentVote]">
    <ArrowIcon direction="up" :size="18" :filled="currentVote === 'up'" @vote="submitVote('up')" />
    <span class="count" aria-live="polite">{{ formatCompactCount(voteCount) }}</span>
    <ArrowIcon
      direction="down"
      :size="18"
      :filled="currentVote === 'down'"
      @vote="submitVote('down')"
    />
  </div>
</template>

<script setup lang="ts">
import ArrowIcon from '@/components/icons/ArrowIcon.vue'
import axios, { AxiosError } from 'axios'
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore } from '@/stores/ui'
import { formatCompactCount } from '@/utils/formatCount'

const props = withDefaults(
  defineProps<{
    type: string
    votes: number
    hasVoted: number | null
    id: number
    // capsule: a quiet pill under posts; inline: lighter, inside comment threads.
    variant?: 'capsule' | 'inline'
  }>(),
  {
    variant: 'capsule',
  },
)

const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()
const voteCount = ref(props.votes)
const currentVote = ref<'up' | 'down' | null>(null)
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const createSubmitURL = (vote: string): string => {
  return `${backendUrl}/vote?vote=${vote}&${
    props.type == 'post' ? 'post_id' : 'comment_id'
  }=${props.id}`
}
const createDeleteURL = (): string => {
  return `${backendUrl}/vote?${props.type == 'post' ? 'post_id' : 'comment_id'}=${props.id}`
}

if (props.hasVoted === 1) {
  currentVote.value = 'up'
} else if (props.hasVoted === -1) {
  currentVote.value = 'down'
}

const deleteVote = (): Promise<void> => {
  return axios
    .delete(createDeleteURL())
    .then(() => {
      if (currentVote.value == 'up') {
        voteCount.value -= 1
      } else if (currentVote.value == 'down') {
        voteCount.value += 1
      }

      currentVote.value = null
    })
    .catch(() => {
      errorBanner.show("Your vote couldn't be removed. Please try again.")
    })
}

const postVote = (vote: string): Promise<void> => {
  return axios
    .post(createSubmitURL(vote), {})
    .then(() => {
      if (vote == 'up') {
        if (currentVote.value == 'down') {
          voteCount.value += 2
        } else {
          voteCount.value += 1
        }

        currentVote.value = 'up'
      } else if (vote == 'down') {
        if (currentVote.value == 'up') {
          voteCount.value -= 2
        } else {
          voteCount.value -= 1
        }

        currentVote.value = 'down'
      }
    })
    .catch((err: AxiosError) => {
      if (err.status === 403) {
        errorBanner.show('You must be logged in to vote.', {
          label: 'Log in',
          run: () => uiStore.openAuth('login'),
        })
        return
      }

      errorBanner.show("Your vote couldn't be submitted. Please try again.")
    })
}

// Each response adjusts the count relative to the vote it started from, so
// overlapping requests (e.g. a double click) would count twice. Ignore clicks
// until the pending vote settles.
let isVoting = false

const submitVote = (vote: string): void => {
  // Voting needs an account: offer one rather than send a request that will fail.
  if (!authStore.isLoggedIn) {
    uiStore.openAuth('login')
    return
  }

  if (isVoting) {
    return
  }

  isVoting = true
  const request = vote == currentVote.value ? deleteVote() : postVote(vote)
  void request.finally(() => {
    isVoting = false
  })
}
</script>

<style scoped>
.voteButtons {
  /* Read by ArrowIcon for its hit area. */
  --vote-hit: calc(var(--control-sm) - 4px);
  display: inline-flex;
  align-items: center;
  font-variant-numeric: tabular-nums;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.capsule {
  height: var(--control-sm);
  padding: 0 2px;
  border-radius: var(--radius-full);
  background-color: var(--fill-capsule);
}

/* A vote tints the whole capsule, so it reads at a glance. */
.capsule.up {
  background-color: color-mix(in srgb, var(--vote-up) 13%, transparent);
}

.capsule.down {
  background-color: color-mix(in srgb, var(--vote-down) 13%, transparent);
}

.inline {
  --vote-hit: 1.75rem;
  margin-left: -0.25rem;
}

.count {
  min-width: 1.25rem;
  padding: 0 0.1rem;
  text-align: center;
  font-size: var(--text-subhead);
  font-weight: 600;
  color: var(--text-1);
  transition: color var(--duration-fast) var(--ease-out);
}

.inline .count {
  min-width: 0.5rem;
  /* Tucks into the arrows' hit areas, so the number sits close to them. */
  margin: 0 -0.2rem;
  font-size: var(--text-footnote);
  font-weight: 500;
  color: var(--text-2);
}

.up .count {
  color: var(--vote-up);
}

.down .count {
  color: var(--vote-down);
}

/* Bigger targets for fingers; they overlap the count so it stays as close. */
@media (pointer: coarse) {
  .inline {
    --vote-hit: 2.25rem;
    margin-left: -0.625rem;
  }

  .inline > .voteArrow {
    margin: 0 -0.375rem;
  }
}
</style>
