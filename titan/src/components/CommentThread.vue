<template>
  <article class="commentThread">
    <span class="threadDot" aria-hidden="true" />
    <span class="threadLine" aria-hidden="true" />

    <div class="commentBody">
      <div class="metadataContainer">
        <router-link class="metadata username" :to="`/@${comment.user.username}`">
          {{ comment.user.username }}
        </router-link>

        <span class="metadata timeUploaded" :title="`Posted at ${absoluteDate}`">
          {{ postedDate }}
        </span>
      </div>

      <p class="content">{{ comment.content }}</p>

      <div class="actions">
        <VoteButtons
          :id="comment.id"
          :votes="comment.votes"
          :has-voted="comment.hasVoted"
          type="comment"
          size="small"
        />

        <button class="action reply" type="button" @click="replyToggled = !replyToggled">
          <ChatCircleIcon :size="19" />
          <span>Reply</span>
        </button>
      </div>

      <div v-if="replyToggled" class="replyComposer">
        <template v-if="authStore.isLoggedIn">
          <textarea
            ref="replyInputRef"
            v-model="replyContent"
            class="replyTextarea"
            rows="1"
            :placeholder="`Reply as ${authStore.getUser.username}...`"
            @input="autoGrowReply"
          />

          <p v-if="replyError" class="feedback error">{{ replyError }}</p>

          <div class="replyButtons">
            <CharacterCounter class="replyCounter" :text="replyContent" :max="COMMENT_MAX_LENGTH" />
            <button type="button" class="cancelButton" @click="cancelReply">Cancel</button>
            <SubmitButton :disabled="isSendingReply" @click="submitReply">
              <span v-if="isSendingReply" key="spinner" class="replySpinner">
                <SpinnerLoader
                  :size="20"
                  bgColor="var(--accent-color)"
                  fgColor="var(--accent-text)"
                />
              </span>
              <span v-else key="label" class="submitLabel">Reply</span>
            </SubmitButton>
          </div>
        </template>

        <p v-else class="feedback info">Log in to your account to send a reply.</p>
      </div>

      <CommentThread
        v-for="reply in replies"
        :key="reply.id"
        :comment="reply"
        :post-id="postId"
        :level="level + 1"
        :sort="sort"
      />

      <InfiniteScrollFooter
        v-if="repliesStatus === 'loaded'"
        :loading="isLoadingMoreReplies"
        :has-more="hasMoreReplyPages"
        :failed="loadMoreRepliesFailed"
        :spinner-size="20"
        @load-more="loadMoreReplies"
        @retry="retryReplies"
      />

      <RouterLink
        v-if="showSeeMoreReplies"
        class="seeMoreReplies"
        :to="{ name: 'post', params: { post_id: postId, comment_id: String(comment.id) } }"
      >
        See more replies
      </RouterLink>
    </div>
  </article>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, inject, nextTick, onMounted, ref, watch } from 'vue'
import ChatCircleIcon from '@/components/icons/ChatCircleIcon.vue'
import InfiniteScrollFooter from '@/components/InfiniteScrollFooter.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import CharacterCounter from '@/components/CharacterCounter.vue'
import { COMMENT_MAX_LENGTH, countCharacters } from '@/utils/characterCount'
import VoteButtons from '@/components/VoteButtons.vue'
import { usePaginatedList } from '@/composables/usePaginatedList'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { formatRelativeTime } from '@/utils/relativeTime'
import { waitForMinimumVisibleTime } from '@/config/loading'
import type { Comment, CommentsResponse } from '@/types/comment'

const MAX_AUTO_EXPAND_LEVEL = 3

const props = defineProps<{
  comment: Comment
  postId: string | number
  level: number
  sort: 'new' | 'top'
}>()

const incrementComments = inject<() => void>('incrementComments', () => {})

const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const replyToggled = ref(false)
const replyContent = ref('')
const replyError = ref('')
const isSendingReply = ref(false)
const replyInputRef = ref<HTMLTextAreaElement | null>(null)

const postedDate = computed(() => formatRelativeTime(props.comment.inserted_at))
const absoluteDate = computed(() => new Date(props.comment.inserted_at).toLocaleString())
const hasMoreReplies = computed(() => Boolean(props.comment.replies))
const showSeeMoreReplies = computed(
  () => props.level >= MAX_AUTO_EXPAND_LEVEL && hasMoreReplies.value,
)

const {
  items: replies,
  status: repliesStatus,
  isLoadingMore: isLoadingMoreReplies,
  loadMoreFailed: loadMoreRepliesFailed,
  hasMore: hasMoreReplyPages,
  reload: fetchReplies,
  loadMore: loadMoreReplies,
  retry: retryReplies,
} = usePaginatedList<Comment>(
  async (cursor) => {
    if (!backendUrl) {
      throw new Error('VITE_BACKEND_URL is not set')
    }

    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.get<CommentsResponse>(`${base}/comments`, {
      params: {
        post_id: props.postId,
        parent_comment_id: props.comment.id,
        limit: 10,
        sort: props.sort,
        ...(cursor ? { cursor } : {}),
      },
    })

    return { items: response.data.comments, nextCursor: response.data.next_cursor }
  },
  {
    // The "See more replies" affordance only relies on comment.replies from
    // the parent fetch, so a failed first fetch of replies can fail silently.
    onError: () => {
      if (repliesStatus.value !== 'error') {
        errorBanner.show("More replies couldn't be loaded. Please try again.")
      }
    },
  },
)

onMounted(() => {
  if (props.level < MAX_AUTO_EXPAND_LEVEL) {
    void fetchReplies()
  }
})

const autoGrowReply = async () => {
  await nextTick()

  const textarea = replyInputRef.value
  if (!textarea) {
    return
  }

  textarea.style.height = 'auto'
  textarea.style.height = `${textarea.scrollHeight + 2}px`
}

const cancelReply = () => {
  replyToggled.value = false
  replyContent.value = ''
  replyError.value = ''
}

const submitReply = async () => {
  if (!backendUrl || isSendingReply.value) {
    return
  }

  const content = replyContent.value.trim()
  if (!content) {
    replyError.value = 'Reply cannot be empty'
    return
  }

  if (countCharacters(content) > COMMENT_MAX_LENGTH) {
    replyError.value = `Reply must be ${COMMENT_MAX_LENGTH} characters or fewer`
    return
  }

  isSendingReply.value = true
  replyError.value = ''
  const submitStartedAt = Date.now()
  let succeeded = false

  try {
    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.post<Comment>(`${base}/comment`, {
      post_id: props.postId,
      comment_id: props.comment.id,
      content,
    })

    // The create endpoint doesn't compute an aggregate vote total for a
    // brand-new comment (it comes back as `[]`), so seed it ourselves.
    replies.value.unshift({ ...response.data, votes: 0, hasVoted: null })
    incrementComments()
    succeeded = true
  } catch (err) {
    replyError.value =
      (axios.isAxiosError(err) && err.response?.data?.errors?.content?.[0]) ||
      "Reply couldn't be sent. Please try again."
  } finally {
    // Wait before closing the composer too, so the spinner (and the
    // composer it lives in) stays visible for the full minimum duration.
    await waitForMinimumVisibleTime(submitStartedAt)
    isSendingReply.value = false

    if (succeeded) {
      cancelReply()
    }
  }
}

watch(replyToggled, async (open) => {
  if (!open) {
    return
  }

  await nextTick()
  replyInputRef.value?.focus()
})
</script>

<style scoped>
.commentThread {
  position: relative;
  margin-top: 1rem;
  padding-left: 2rem;
}

.threadDot {
  position: absolute;
  top: 0;
  left: 0;
  width: 1.5rem;
  height: 1.5rem;
  border-radius: 50%;
  background-color: var(--bg-3);
}

.threadLine {
  position: absolute;
  top: 1.75rem;
  left: 0.75rem;
  bottom: 0;
  width: 1px;
  background-color: var(--bg-2);
}

.metadataContainer {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}

.metadata {
  font-size: 0.85rem;
  color: var(--text-2);
  text-decoration: none;
}

.metadata.username {
  color: var(--text-1);
  font-weight: 600;
}

.metadata.username:hover {
  text-decoration: underline;
}

.content {
  margin-top: 0.25rem;
  line-height: 1.4;
  white-space: pre-wrap;
}

.actions {
  margin-top: 0.25rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.action {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.9rem;
  color: var(--text-2);
  border: none;
  background: transparent;
  cursor: pointer;
  padding: 0.25rem 0.5rem;
  border-radius: 8px;
}

.action:hover {
  background: var(--bg-2);
}

.replyComposer {
  margin-top: 0.6rem;
  max-width: 30rem;
}

.replyTextarea {
  width: 100%;
  border: 1px solid var(--bg-2);
  border-radius: 10px;
  background-color: var(--bg-1);
  color: var(--text-1);
  font-size: 0.95rem;
  font-family: inherit;
  padding: 0.65rem 0.75rem;
  resize: none;
  min-height: 2.5rem;
  overflow-y: hidden;
}

.replyTextarea::placeholder {
  color: var(--text-3);
}

.replyButtons {
  margin-top: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 0.5rem;
}

.replyCounter {
  margin-right: auto;
}

.cancelButton {
  border: none;
  background: transparent;
  color: var(--text-2);
  font-size: 1rem;
  padding: 0.5rem 0.75rem;
  border-radius: 10px;
  cursor: pointer;
}

.cancelButton:hover {
  background: var(--bg-2);
}

.replySpinner {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.submitLabel {
  color: var(--accent-text);
}

.feedback {
  font-size: 0.9rem;
  margin-top: 0.4rem;
}

.feedback.error {
  color: var(--text-error);
}

.feedback.info {
  color: var(--text-2);
}

.seeMoreReplies {
  display: inline-block;
  margin-top: 0.6rem;
  font-size: 0.9rem;
  color: var(--text-2);
  background: var(--bg-2);
  padding: 0.35rem 0.75rem;
  border-radius: 10px;
  text-decoration: none;
}

.seeMoreReplies:hover {
  background: var(--bg-3);
}
</style>
