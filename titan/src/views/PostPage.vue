<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, onBeforeUnmount, provide, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import CommentThread from '@/components/CommentThread.vue'
import InfiniteScrollFooter from '@/components/InfiniteScrollFooter.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { usePaginatedList } from '@/composables/usePaginatedList'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import type { Post } from '@/types/post'
import type { Comment, CommentsResponse } from '@/types/comment'
import PostCard from '@/components/PostCard.vue'
import SubmitButton from '@/components/SubmitButton.vue'

type CommentSort = 'new' | 'top'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const postId = computed(() => String(route.params.post_id))
const commentId = computed(() => (route.params.comment_id ? String(route.params.comment_id) : null))
const isSingleCommentView = computed(() => commentId.value !== null)

const commentSortOptions: Array<{ label: string; value: CommentSort }> = [
  { label: 'New', value: 'new' },
  { label: 'Top', value: 'top' },
]

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

const commentSort = ref<CommentSort>('new')

const newCommentContent = ref('')
const isPostingComment = ref(false)
const postCommentError = ref('')

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

const loadPost = async () => {
  const postLoadStartedAt = Date.now()
  let shouldRedirectToNotFound = false

  fetchingPost.value = true
  error.value = ''
  post.value = null
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
}

const commentsError = ref('')

const {
  items: comments,
  status: commentsStatus,
  isLoadingMore: isLoadingMoreComments,
  loadMoreFailed: loadMoreCommentsFailed,
  hasMore: hasMoreComments,
  reload: loadComments,
  loadMore: loadMoreComments,
  retry: retryComments,
} = usePaginatedList<Comment>(
  async (cursor) => {
    if (!backendUrl) {
      throw new Error('VITE_BACKEND_URL is not set')
    }

    const base = backendUrl.replace(/\/$/, '')

    if (commentId.value) {
      const response = await axios.get<Comment>(`${base}/comments/${commentId.value}`)
      return { items: [response.data], nextCursor: null }
    }

    const response = await axios.get<CommentsResponse>(`${base}/comments`, {
      params: {
        post_id: postId.value,
        limit: 10,
        sort: commentSort.value,
        ...(cursor ? { cursor } : {}),
      },
    })

    return { items: response.data.comments, nextCursor: response.data.next_cursor }
  },
  {
    onError: (err) => {
      if (commentsStatus.value !== 'error') {
        errorBanner.show("More comments couldn't be loaded. Please try again.")
      } else if (axios.isAxiosError(err) && err.response?.status === 404 && commentId.value) {
        commentsError.value = "Comment couldn't be found"
      } else {
        commentsError.value = "Comments couldn't be loaded"
      }
    },
  },
)

const onCommentSortChange = (value: string) => {
  if (value !== 'new' && value !== 'top') {
    return
  }

  commentSort.value = value
}

const submitComment = async () => {
  if (!backendUrl || isPostingComment.value || !post.value) {
    return
  }

  const content = newCommentContent.value.trim()
  if (!content) {
    postCommentError.value = 'Comment cannot be empty'
    return
  }

  isPostingComment.value = true
  postCommentError.value = ''
  const submitStartedAt = Date.now()

  try {
    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.post<Comment>(`${base}/comment`, {
      post_id: post.value.id,
      content,
    })

    // The create endpoint doesn't compute an aggregate vote total for a
    // brand-new comment (it comes back as `[]`), so seed it ourselves.
    comments.value.unshift({ ...response.data, votes: 0, hasVoted: null })
    numberOfComments.value += 1
    newCommentContent.value = ''

    await nextTick()
    if (commentInput.value) {
      commentInput.value.style.height = 'auto'
    }
  } catch {
    postCommentError.value = "Comment couldn't be posted. Please try again."
  } finally {
    await waitForMinimumVisibleTime(submitStartedAt)
    isPostingComment.value = false
  }
}

// The post no longer exists, so leave for its moon (replace, so Back doesn't return here).
const onPostDeleted = () => {
  if (post.value) {
    void router.replace({ name: 'moon', params: { moon: post.value.moon.name } })
  }
}

const incrementComments = () => {
  numberOfComments.value += 1
}

provide('incrementComments', incrementComments)

watch(postId, () => void loadPost(), { immediate: true })
watch([postId, commentId, commentSort], () => void loadComments(), { immediate: true })

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
        <PostCard :post="post" :post-page-mode="true" @deleted="onPostDeleted" />

        <RouterLink
          v-if="isSingleCommentView"
          class="seeAllCommentsButton"
          :to="{ name: 'post', params: { post_id: postId } }"
        >
          See all comments on this post
        </RouterLink>

        <template v-else>
          <h1>{{ numberOfComments }} {{ numberOfComments === 1 ? 'Comment' : 'Comments' }}</h1>

          <div v-if="authStore.isLoggedIn" class="commentWritingSection">
            <textarea
              ref="commentInput"
              v-model="newCommentContent"
              class="commentInput"
              :placeholder="randomPlaceholder"
              rows="1"
              @input="autoGrowCommentInput"
            ></textarea>
            <div class="divider"></div>
            <SubmitButton :disabled="isPostingComment" @click="submitComment">
              <span class="submitSpinner" :class="{ visible: isPostingComment }" aria-hidden="true">
                <SpinnerLoader
                  :size="20"
                  bgColor="var(--accent-color)"
                  fgColor="var(--accent-text)"
                />
              </span>
              <span class="submitLabel" :class="{ hidden: isPostingComment }">Post</span>
            </SubmitButton>
          </div>
          <p v-else class="loginPrompt">Log in to your account to post a comment.</p>

          <p v-if="postCommentError" class="feedback error">{{ postCommentError }}</p>

          <div v-if="comments.length > 0" class="commentSortRow">
            <span class="commentSortLabel">Sort by</span>
            <SegmentedControl
              class="commentSort"
              :model-value="commentSort"
              :options="commentSortOptions"
              @update:model-value="onCommentSortChange"
            />
          </div>
        </template>

        <div class="commentsSection">
          <p v-if="commentsStatus === 'idle' || commentsStatus === 'loading'" class="loadingText">
            Loading comments...
          </p>
          <p v-else-if="commentsStatus === 'error'" class="feedback error">{{ commentsError }}</p>
          <template v-else>
            <p v-if="comments.length === 0" class="emptyText">No comments yet.</p>

            <CommentThread
              v-for="comment in comments"
              :key="comment.id"
              :comment="comment"
              :post-id="postId"
              :level="0"
              :sort="commentSort"
            />

            <InfiniteScrollFooter
              v-if="!isSingleCommentView"
              class="commentsFooter"
              :loading="isLoadingMoreComments"
              :has-more="hasMoreComments"
              :failed="loadMoreCommentsFailed"
              :spinner-size="24"
              @load-more="loadMoreComments"
              @retry="retryComments"
            />
          </template>
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

.emptyText {
  color: var(--text-3);
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

.commentWritingSection button {
  display: inline-grid;
  place-items: center;
  align-self: flex-end;
  margin: 0.5rem 1rem;
}

.submitSpinner,
.submitLabel {
  grid-area: 1 / 1;
}

.submitSpinner {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
}

.submitSpinner.visible {
  opacity: 1;
}

.submitLabel {
  color: var(--accent-text);
  opacity: 1;
}

.submitLabel.hidden {
  opacity: 0;
}

.loginPrompt {
  color: var(--text-2);
  margin-top: 0.5rem;
}

.feedback.error {
  color: var(--text-error);
  margin-top: 0.5rem;
}

.commentSortRow {
  margin-top: 1.75rem;
  margin-left: 0.5rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.commentSortLabel {
  color: var(--text-2);
  font-size: 0.9rem;
}

.commentSort {
  width: auto;
  max-width: 10rem;
  margin-bottom: 0;
}

.seeAllCommentsButton {
  display: inline-block;
  margin-top: 1.5rem;
  margin-left: 0.5rem;
  color: var(--text-2);
  background: var(--bg-2);
  padding: 0.5rem 0.9rem;
  border-radius: 10px;
  text-decoration: none;
  align-self: flex-start;
}

.seeAllCommentsButton:hover {
  background: var(--bg-3);
}

.commentsFooter {
  margin-top: 1.5rem;
}
</style>
