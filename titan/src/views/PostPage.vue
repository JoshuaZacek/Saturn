<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, onBeforeUnmount, provide, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import CommentComposer from '@/components/CommentComposer.vue'
import CommentThread from '@/components/CommentThread.vue'
import EmptyState from '@/components/EmptyState.vue'
import InfiniteScrollFooter from '@/components/InfiniteScrollFooter.vue'
import PostCard from '@/components/PostCard.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import CaretLeftIcon from '@/components/icons/CaretLeftIcon.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { usePaginatedList } from '@/composables/usePaginatedList'
import { notFoundLocation } from '@/router'
import { useAuthStore } from '@/stores/auth'
import { useAvatarStore } from '@/stores/avatars'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore } from '@/stores/ui'
import type { Post } from '@/types/post'
import type { Comment, CommentsResponse } from '@/types/comment'
import { COMMENT_MAX_LENGTH, countCharacters } from '@/utils/characterCount'
import { formatCompactCount } from '@/utils/formatCount'

type CommentSort = 'new' | 'top'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()
const avatarStore = useAvatarStore()
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
const fetchingPost = ref(true)
const error = ref('')
const loadingDots = ref('...')
const loadingDotsWidth = computed(() => `${loadingDots.value.length || 0}ch`)

const commentsTitle = computed(() => {
  const count = numberOfComments.value
  return count === 0
    ? 'Comments'
    : `${formatCompactCount(count)} ${count === 1 ? 'comment' : 'comments'}`
})

// The sidebar shows the moon this post lives in, with its picture.
watch(post, (current) => {
  uiStore.setPostMoon(current?.moon.name ?? null)
  if (current) {
    avatarStore.remember('moon', current.moon.name, current.moon)
  }
})
onBeforeUnmount(() => uiStore.setPostMoon(null))

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
    await router.replace(notFoundLocation(route))
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

  if (countCharacters(content) > COMMENT_MAX_LENGTH) {
    postCommentError.value = `Comment must be ${COMMENT_MAX_LENGTH} characters or fewer`
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
  } catch (err) {
    postCommentError.value =
      (axios.isAxiosError(err) && err.response?.data?.errors?.content?.[0]) ||
      "Comment couldn't be posted. Please try again."
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

// Replies add to the count; deleted comments that leave the thread take away.
provide('adjustCommentCount', (delta: number) => {
  numberOfComments.value = Math.max(0, numberOfComments.value + delta)
})

const onCommentRemoved = (id: number) => {
  comments.value = comments.value.filter((comment) => comment.id !== id)
}

watch(postId, () => void loadPost(), { immediate: true })
// Re-sorting keeps the current comments up (dimmed) until the new order
// arrives, then fades it in while the card eases to its new height.
const commentsSection = ref<HTMLElement | null>(null)
const commentsPhase = ref<'idle' | 'stale' | 'entering'>('idle')
const prefersReducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches

watch(
  [postId, commentId],
  () => {
    commentsPhase.value = 'idle'
    void loadComments()
  },
  { immediate: true },
)

watch(commentSort, () => {
  commentsPhase.value = comments.value.length > 0 ? 'stale' : 'idle'
  void loadComments({ keepItems: true })
})

// Runs before the new comments render, so the old height can still be read.
watch(
  commentsStatus,
  (status) => {
    if (commentsPhase.value !== 'stale' || status === 'loading') {
      return
    }

    if (status !== 'loaded' || prefersReducedMotion()) {
      commentsPhase.value = 'idle'
      return
    }

    const section = commentsSection.value
    const startHeight = section?.offsetHeight ?? 0
    commentsPhase.value = 'entering'

    void nextTick(() => {
      if (!section) {
        return
      }

      const endHeight = section.offsetHeight
      if (endHeight === startHeight) {
        return
      }

      section.style.overflow = 'hidden'
      const animation = section.animate(
        [{ height: `${startHeight}px` }, { height: `${endHeight}px` }],
        { duration: 260, easing: 'cubic-bezier(0.2, 0.8, 0.2, 1)' },
      )
      void animation.finished.finally(() => {
        section.style.overflow = ''
      })
    })
  },
  { flush: 'pre' },
)

onBeforeUnmount(() => {
  stopLoadingDotsAnimation()
})
</script>

<template>
  <main class="postPage">
    <template v-if="fetchingPost">
      <Transition name="post-loading" appear>
        <div class="loadingState" aria-live="polite" aria-busy="true">
          <SpinnerLoader :size="36" bg-color="var(--bg-1)" fg-color="var(--text-3)" />
          <p class="loadingText">
            Loading post<span class="loadingDots" :style="{ width: loadingDotsWidth }">{{
              loadingDots
            }}</span>
          </p>
        </div>
      </Transition>
    </template>

    <template v-else-if="post">
      <RouterLink class="backLink" :to="{ name: 'moon', params: { moon: post.moon.name } }">
        <CaretLeftIcon :size="16" />
        <span>/{{ post.moon.name }}</span>
      </RouterLink>

      <!-- The back link already names the moon, so the post leads with its author. -->
      <PostCard :post="post" :post-page-mode="true" hide-moon @deleted="onPostDeleted" />

      <section class="comments" aria-labelledby="comments-heading">
        <header class="commentsHeader">
          <h2 id="comments-heading" class="commentsTitle">
            {{ isSingleCommentView ? 'Thread' : commentsTitle }}
          </h2>

          <RouterLink
            v-if="isSingleCommentView"
            class="btn-secondary"
            :to="{ name: 'post', params: { post_id: postId } }"
          >
            See all comments
          </RouterLink>
          <SegmentedControl
            v-else-if="comments.length > 1"
            size="sm"
            label="Sort comments"
            :model-value="commentSort"
            :options="commentSortOptions"
            @update:model-value="onCommentSortChange"
          />
        </header>

        <template v-if="!isSingleCommentView">
          <CommentComposer
            v-if="authStore.isLoggedIn"
            v-model="newCommentContent"
            label="Add a comment"
            placeholder="Add a comment"
            :loading="isPostingComment"
            :error="postCommentError"
            @submit="submitComment"
          />
          <div v-else class="loginPrompt">
            <p>Log in to join the conversation.</p>
            <div class="loginButtons">
              <SubmitButton size="sm" variant="secondary" @click="uiStore.openAuth('signup')">
                Sign up
              </SubmitButton>
              <SubmitButton size="sm" @click="uiStore.openAuth('login')">Log in</SubmitButton>
            </div>
          </div>
        </template>

        <div ref="commentsSection" class="commentsSection">
          <div
            v-if="
              (commentsStatus === 'idle' || commentsStatus === 'loading') && comments.length === 0
            "
            class="commentsLoading"
            aria-busy="true"
          >
            <SpinnerLoader :size="24" bg-color="var(--bg-1)" fg-color="var(--text-3)" />
          </div>
          <EmptyState v-else-if="commentsStatus === 'error'" :title="commentsError">
            <button class="btn-secondary" type="button" @click="retryComments">Try again</button>
          </EmptyState>
          <div
            v-else
            class="commentsList"
            :class="commentsPhase"
            :aria-busy="commentsPhase === 'stale'"
            @animationend.self="commentsPhase = 'idle'"
          >
            <EmptyState v-if="comments.length === 0" title="No comments yet" />

            <CommentThread
              v-for="comment in comments"
              :key="comment.id"
              :comment="comment"
              :post-id="postId"
              :level="0"
              :sort="commentSort"
              @removed="onCommentRemoved"
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
          </div>
        </div>
      </section>
    </template>

    <EmptyState v-else class="postError" :title="error">
      <button class="btn-secondary" type="button" @click="loadPost">Try again</button>
    </EmptyState>
  </main>
</template>

<style scoped>
/* Centred in the area beside the sidebar (and under the phone top bar). */
.loadingState {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  flex-direction: column;
  justify-content: center;
  gap: 1rem;
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

.post-loading-enter-active,
.post-loading-appear-active {
  transition:
    opacity var(--duration-base) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.post-loading-enter-from,
.post-loading-appear-from {
  opacity: 0;
  transform: translateY(0.5rem) scale(0.99);
}

.post-loading-enter-to,
.post-loading-appear-to {
  opacity: 1;
  transform: translateY(0) scale(1);
}

.postPage {
  width: 100%;
  max-width: var(--column-width);
  display: flex;
  flex-direction: column;
  align-items: stretch;
  /* Grow with the content instead of stretching to the window, so the
     spacer below is part of the scrollable height. */
  align-self: flex-start;
}

/* Room below the last comment, as below the feeds. */
.postPage::after {
  content: '';
  flex-shrink: 0;
  height: 5rem;
}

/* Back to the moon the post lives in. Its text lines up with the article's. */
.backLink {
  align-self: flex-start;
  display: inline-flex;
  align-items: center;
  gap: 0.15rem;
  margin: -0.35rem 0 1.25rem -0.55rem;
  padding: 0.3rem 0.65rem 0.3rem 0.35rem;
  border-radius: var(--radius-full);
  color: var(--text-2);
  font-size: var(--text-subhead);
  font-weight: 500;
  text-decoration: none;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .backLink:hover {
    background-color: var(--fill-hover);
    color: var(--text-1);
  }
}

.backLink:active {
  background-color: var(--fill-pressed);
}

.comments {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--separator);
}

.commentsHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  min-height: var(--control-sm);
}

.commentsTitle {
  font-size: var(--text-title-3);
  font-weight: 600;
}

.loginPrompt {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem 1rem;
  padding: 0.75rem 0.75rem 0.75rem 1rem;
  border-radius: var(--radius-lg);
  background-color: var(--surface);
  box-shadow: var(--shadow-sm);
  font-size: var(--text-subhead);
  color: var(--text-2);
}

.loginButtons {
  display: flex;
  gap: 0.5rem;
}

.commentsSection {
  margin-top: 0.5rem;
}

.commentsLoading {
  display: flex;
  justify-content: center;
  padding: 2rem 0;
}

.commentsList > .commentThread + .commentThread {
  margin-top: 1.5rem;
}

/* The footer is an invisible scroll sentinel until it has something to say. */
.commentsFooter:has(> :not(.sentinel)) {
  margin-top: 1.5rem;
}

.commentsList {
  transition: opacity var(--duration-fast) var(--ease-out);
}

/* The old order, while the new one loads. */
.commentsList.stale {
  opacity: 0.4;
  pointer-events: none;
}

.commentsList.entering {
  animation: comments-in var(--duration-base) var(--ease-out);
}

@keyframes comments-in {
  from {
    opacity: 0;
    transform: translateY(4px);
  }
}

.postError {
  margin-top: 4rem;
}
</style>
