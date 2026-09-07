<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, onBeforeMount, onBeforeUnmount, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import type { Post } from '@/types/post'
import PostCard from '@/components/PostCard.vue'
import SubmitButton from '@/components/SubmitButton.vue'

const route = useRoute()
const router = useRouter()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const postId = computed(() => String(route.params.post_id))
const post = ref<Post | null>(null)
const numberOfComments = ref(0)
const commentInput = ref<HTMLTextAreaElement | null>(null)
const fetchingPost = ref(true)
const error = ref('')
const loadingDots = ref('...')
const loadingDotsWidth = computed(() => `${loadingDots.value.length || 0}ch`)
const randomPlaceholder = computed(() => {
  const placeholders = [
    'Share your thoughts...',
    "What's on your mind?",
    'Join the discussion...',
    'Leave a comment...',
    'Add your perspective...',
  ]

  const index = Math.floor(Math.random() * placeholders.length)
  return placeholders[index]!
})

const loadingDotSequence = ['', '.', '..', '...'] as const
let loadingDotsInterval: ReturnType<typeof setInterval> | null = null

const startLoadingDotsAnimation = () => {
  if (loadingDotsInterval) {
    return
  }

  let currentIndex = 0
  loadingDots.value = loadingDotSequence[currentIndex]!
  loadingDotsInterval = setInterval(() => {
    currentIndex = (currentIndex + 1) % loadingDotSequence.length
    loadingDots.value = loadingDotSequence[currentIndex]!
  }, 1000)
}

const stopLoadingDotsAnimation = () => {
  if (!loadingDotsInterval) {
    return
  }

  clearInterval(loadingDotsInterval)
  loadingDotsInterval = null
}

const autoGrowCommentInput = async () => {
  await nextTick()

  const textArea = commentInput.value
  if (!textArea) {
    return
  }

  const computedStyle = window.getComputedStyle(textArea)
  const minHeight = Number.parseFloat(computedStyle.minHeight) || 0
  const borderTop = Number.parseFloat(computedStyle.borderTopWidth) || 0
  const borderBottom = Number.parseFloat(computedStyle.borderBottomWidth) || 0

  textArea.style.height = 'auto'
  const nextHeight = Math.max(textArea.scrollHeight + borderTop + borderBottom, minHeight)
  textArea.style.height = `${nextHeight}px`
}

onBeforeMount(async () => {
  const postLoadStartedAt = Date.now()
  let shouldRedirectToNotFound = false

  startLoadingDotsAnimation()

  if (!backendUrl) {
    error.value = "Post couldn't be loaded"
  } else {
    try {
      const base = backendUrl.replace(/\/$/, '')
      const response = await axios.get<Post>(`${base}/post/${postId.value}`, {
        withCredentials: true,
      })

      post.value = response.data
      numberOfComments.value = response.data.comments
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.status === 404) {
        shouldRedirectToNotFound = true
      } else {
        error.value = "Post couldn't be loaded"
      }
    }
  }

  await waitForMinimumVisibleTime(postLoadStartedAt)
  fetchingPost.value = false
  stopLoadingDotsAnimation()

  if (shouldRedirectToNotFound) {
    await router.replace({ name: 'not-found' })
  }
})

onBeforeUnmount(() => {
  stopLoadingDotsAnimation()
})
</script>

<template>
  <main>
    <template v-if="fetchingPost">
      <Transition name="post-loading" appear>
        <div class="loadingState" aria-live="polite" aria-busy="true">
          <SpinnerLoader :size="36" bgColor="var(--bg-sub)" fgColor="var(--text-3)" />
          <p class="loadingText">
            Loading post<span class="loadingDots" :style="{ width: loadingDotsWidth }">{{
              loadingDots
            }}</span>
          </p>
        </div>
      </Transition>
    </template>
    <template v-else>
      <section v-if="post" class="postHeader">
        <PostCard :post="post" :post-page-mode="true" />
        <h1>{{ numberOfComments }} {{ numberOfComments === 1 ? 'Comment' : 'Comments' }}</h1>

        <div class="commentWritingSection">
          <textarea
            ref="commentInput"
            class="commentInput"
            :placeholder="randomPlaceholder"
            rows="1"
            @input="autoGrowCommentInput"
          ></textarea>
          <div class="divider"></div>
          <SubmitButton>Post</SubmitButton>
        </div>

        <div class="commentsSection">
          <p>comments will be displayed here</p>
        </div>
      </section>

      <p v-else class="loadingText">{{ error }}</p>
    </template>
  </main>
</template>

<style scoped>
.loadingState {
  display: flex;
  align-items: center;
  flex-direction: column;
  justify-content: center;
  gap: 1rem;
  height: 100vh;
  position: absolute;
  top: 0;
}

.loadingText,
.loadingDots {
  color: var(--text-3);
}

.loadingDots {
  display: inline-block;
  overflow: hidden;
  vertical-align: bottom;
  transition: width 180ms ease;
  will-change: width;
}

main {
  width: 40rem;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.post-loading-enter-active,
.post-loading-appear-active {
  transition:
    opacity 180ms ease,
    transform 180ms ease;
}

.post-loading-enter-from,
.post-loading-appear-from {
  opacity: 0;
  transform: translateY(0.5rem) scale(0.98);
}

.post-loading-enter-to,
.post-loading-appear-to {
  opacity: 1;
  transform: translateY(0) scale(1);
}

.commentsSection {
  border: 1px solid var(--bg-2);
  border-radius: 0.75rem;
  padding: 1rem 1.25rem;
  max-width: 40rem;
  background-color: var(--bg-sub);
  margin-top: 1.5rem;
}

h1 {
  margin-top: 2.5rem;
  margin-left: 0.5rem;
  margin-bottom: 1rem;
  font-size: 1.25rem;
}

textarea {
  width: 100%;
  border-radius: 0.75rem 0.75rem 0 0;
  border: none;
  padding: 1rem 1rem;
  font-size: 1rem;
  resize: none;
  min-height: 5rem;
}

.commentWritingSection {
  width: 100%;
  border-radius: 0.75rem;
  border: 1px solid var(--bg-2);
  font-size: 1rem;
  background-color: var(--bg-sub);
  display: flex;
  flex-direction: column;
}

.divider {
  width: calc(100% - 1.5rem);
  height: 1px;
  background-color: var(--bg-2);
  align-self: center;
}

button {
  align-self: flex-end;
  margin: 0.5rem 1rem;
}
</style>
