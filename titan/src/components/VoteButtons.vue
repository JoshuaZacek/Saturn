<template>
  <div class="voteButtons">
    <ArrowIcon direction="up" :filled="currentVote === 'up'" @vote="submitVote('up')" />
    <span>{{ voteCount }}</span>
    <ArrowIcon direction="down" :filled="currentVote === 'down'" @vote="submitVote('down')" />
  </div>
</template>

<script setup lang="ts">
import ArrowIcon from '@/components/icons/ArrowIcon.vue'
import axios, { AxiosError } from 'axios'
import { ref } from 'vue'

const props = defineProps<{
  type: string
  votes: number
  hasVoted: number | null
  id: number
}>()

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

const deleteVote = (): void => {
  axios
    .delete(createDeleteURL(), { withCredentials: true })
    .then(() => {
      if (currentVote.value == 'up') {
        voteCount.value -= 1
      } else if (currentVote.value == 'down') {
        voteCount.value += 1
      }

      currentVote.value = null
    })
    .catch(() => {
      alert('Sorry, something went wrong.')
    })
}

const submitVote = (vote: string): void => {
  if (vote == currentVote.value) {
    deleteVote()
    return
  }

  axios
    .post(createSubmitURL(vote), {}, { withCredentials: true })
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
        alert('You must be logged in to vote.')
        return
      }

      alert('Sorry, something went wrong.')
    })
}
</script>

<style scoped>
.voteButtons {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 1rem;
}
</style>
