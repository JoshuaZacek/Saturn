<template>
  <article
    ref="threadRef"
    class="commentThread"
    :class="{ hasReplies, collapsed, lineHover, deleted: current.deleted }"
  >
    <!-- A reply's stretch of its parent's line: clicking it collapses the parent. -->
    <span
      class="parentLine"
      aria-hidden="true"
      @click="emit('collapseParent')"
      @mouseenter="emit('hoverParent', true)"
      @mouseleave="emit('hoverParent', false)"
    />

    <div class="commentRow">
      <button
        v-if="collapsed"
        ref="expandButtonRef"
        class="expandButton"
        type="button"
        aria-label="Expand thread"
        title="Expand thread"
        :aria-expanded="false"
        @click="expand"
      >
        <PlusIcon :size="14" />
      </button>
      <!-- A deleted comment's author isn't shown. -->
      <span v-else-if="!current.user" class="deletedAvatar" aria-hidden="true" />
      <!-- The username beside it is the link for keyboards and screen readers. -->
      <RouterLink v-else class="avatarLink" :to="profileLocation" tabindex="-1" aria-hidden="true">
        <UserAvatar
          :name="current.user.username"
          :color="current.user.avatar_color"
          :image="current.user.avatar_image"
          :size="28"
        />
      </RouterLink>

      <button
        v-if="hasReplies && !collapsed"
        ref="threadLineRef"
        class="threadLine"
        type="button"
        aria-label="Collapse thread"
        title="Collapse thread"
        :aria-expanded="true"
        @click="collapse"
        @mouseenter="lineHover = true"
        @mouseleave="lineHover = false"
      />

      <div class="commentBody">
        <div class="meta">
          <span v-if="!current.user" class="deletedName">Deleted</span>
          <RouterLink v-else class="username" :to="profileLocation">
            {{ current.user.username }}
          </RouterLink>
          <RelativeTime class="time" :datetime="current.inserted_at" />
          <HoverTooltip v-if="current.edited_at" :text="editedText">
            <span class="edited">edited</span>
          </HoverTooltip>
        </div>

        <div v-show="!collapsed">
          <p v-if="current.deleted" class="content deletedContent">This comment was deleted.</p>
          <div v-else-if="isEditing" class="editArea">
            <CommentComposer
              v-model="draft"
              reply
              label="Edit your comment"
              submit-label="Save"
              :loading="isSaving"
              :error="editError"
              @submit="saveEdit"
              @cancel="cancelEditing"
            />
          </div>
          <p v-else class="content">{{ current.content }}</p>

          <div v-if="!current.deleted && !isEditing" class="actions">
            <VoteButtons
              :id="comment.id"
              :votes="comment.votes"
              :has-voted="comment.hasVoted"
              type="comment"
              variant="inline"
            />

            <button
              class="replyButton"
              type="button"
              aria-label="Reply"
              title="Reply"
              :aria-expanded="replyToggled"
              @click="replyToggled = !replyToggled"
            >
              <ReplyIcon :size="18" />
            </button>

            <ActionMenu
              v-if="isOwner"
              class="options"
              label="Comment options"
              align="start"
              :items="ownerActions"
              :busy="isDeleting"
              @select="onOwnerAction"
            />
          </div>

          <Transition name="reply-area">
            <div v-if="replyToggled && !current.deleted && !isEditing" class="replyArea">
              <CommentComposer
                v-if="authStore.isLoggedIn"
                v-model="replyContent"
                reply
                :label="`Reply to ${current.user?.username}`"
                :placeholder="`Reply to ${current.user?.username}`"
                submit-label="Reply"
                :loading="isSendingReply"
                :error="replyError"
                @submit="submitReply"
                @cancel="cancelReply"
              />
              <div v-else class="replyLogin">
                <span>Log in to reply.</span>
                <SubmitButton size="sm" @click="uiStore.openAuth('login')">Log in</SubmitButton>
              </div>
            </div>
          </Transition>
        </div>
      </div>
    </div>

    <div v-if="hasReplies" v-show="!collapsed" class="replies">
      <CommentThread
        v-for="reply in replies"
        :key="reply.id"
        :comment="reply"
        :post-id="postId"
        :level="level + 1"
        :sort="sort"
        @collapse-parent="collapse"
        @hover-parent="lineHover = $event"
        @removed="onReplyRemoved"
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
import { computed, inject, nextTick, onMounted, ref } from 'vue'
import PlusIcon from '@/components/icons/PlusIcon.vue'
import ReplyIcon from '@/components/icons/ReplyIcon.vue'
import ActionMenu from '@/components/ActionMenu.vue'
import CommentComposer from '@/components/CommentComposer.vue'
import HoverTooltip from '@/components/HoverTooltip.vue'
import InfiniteScrollFooter from '@/components/InfiniteScrollFooter.vue'
import RelativeTime from '@/components/RelativeTime.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import VoteButtons from '@/components/VoteButtons.vue'
import { COMMENT_MAX_LENGTH, countCharacters } from '@/utils/characterCount'
import { useCommentEditing } from '@/composables/useCommentEditing'
import { usePaginatedList } from '@/composables/usePaginatedList'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore } from '@/stores/ui'
import { waitForMinimumVisibleTime } from '@/config/loading'
import type { Comment, CommentsResponse } from '@/types/comment'

const MAX_AUTO_EXPAND_LEVEL = 3
const REPLY_FAILED = "Your reply couldn't be sent. Please try again."

const props = defineProps<{
  comment: Comment
  postId: string | number
  level: number
  sort: 'new' | 'top'
}>()

const emit = defineEmits<{
  collapseParent: []
  hoverParent: [hovering: boolean]
  // Deleted and gone from the thread (not kept as a placeholder for its replies).
  removed: [commentId: number]
}>()

// The post page's comment count.
const adjustCommentCount = inject<(delta: number) => void>('adjustCommentCount', () => {})

const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const replyToggled = ref(false)
const replyContent = ref('')
const replyError = ref('')
const isSendingReply = ref(false)

// Your own comment can be edited and deleted.
const {
  current,
  isOwner,
  editedText,
  isEditing,
  draft,
  editError,
  isSaving,
  isDeleting,
  cancelEditing,
  saveEdit,
  ownerActions,
  onOwnerAction,
} = useCommentEditing(
  () => props.comment,
  () => {
    adjustCommentCount(-1)
    emit('removed', props.comment.id)
  },
)

const profileLocation = computed(() =>
  current.value.user ? `/@${current.value.user.username}` : '',
)
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

// A deleted placeholder is only kept for its replies, so once the last of them
// is gone, the API removes it too, and so does the thread.
const onReplyRemoved = (replyId: number) => {
  replies.value = replies.value.filter((reply) => reply.id !== replyId)

  if (current.value.deleted && replies.value.length === 0 && !hasMoreReplyPages.value) {
    adjustCommentCount(-1)
    emit('removed', props.comment.id)
  }
}

// Lines run from a comment to its replies only when there are some to show.
const hasReplies = computed(() => replies.value.length > 0 || showSeeMoreReplies.value)

const threadRef = ref<HTMLElement | null>(null)
const threadLineRef = ref<HTMLButtonElement | null>(null)
const expandButtonRef = ref<HTMLButtonElement | null>(null)
const collapsed = ref(false)
const lineHover = ref(false)

// Folds the comment down to its name, keeping loaded replies for when it opens.
// Focus follows the toggle only when it was on it, so a mouse click doesn't
// leave a focus ring behind.
const collapse = async () => {
  const hadFocus = document.activeElement === threadLineRef.value
  collapsed.value = true
  lineHover.value = false
  await nextTick()
  // Collapsing from far down a long thread would leave the comment off screen.
  threadRef.value?.scrollIntoView({ block: 'nearest' })
  if (hadFocus) expandButtonRef.value?.focus({ preventScroll: true })
}

const expand = async () => {
  const hadFocus = document.activeElement === expandButtonRef.value
  collapsed.value = false
  await nextTick()
  if (hadFocus) threadLineRef.value?.focus({ preventScroll: true })
}

onMounted(() => {
  if (props.level < MAX_AUTO_EXPAND_LEVEL) {
    void fetchReplies()
  }
})

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
    adjustCommentCount(1)
    succeeded = true
    errorBanner.dismissMessage(REPLY_FAILED)
  } catch (err) {
    const fieldError = axios.isAxiosError(err) && err.response?.data?.errors?.content?.[0]

    // A problem with the text goes under it; a failed request goes in the
    // error banner. The reply stays in the composer either way.
    if (fieldError) {
      replyError.value = fieldError
    } else {
      errorBanner.show(REPLY_FAILED)
    }
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
</script>

<style scoped>
.commentThread {
  --avatar: 28px;
  --gap: 0.75rem;
  --line: 1.5px;
  --line-x: calc(var(--avatar) / 2 - var(--line) / 2);
  --indent: calc(var(--avatar) + var(--gap));
  --reply-gap: 1rem;
  /* Opaque, so the overlapping line pieces don't darken where they meet. */
  --thread-line: color-mix(in srgb, var(--text-1) 13%, var(--bg-1));
  --thread-line-hover: color-mix(in srgb, var(--text-1) 40%, var(--bg-1));
  position: relative;
  /* Clears the phone top bar when a collapse scrolls the comment into view. */
  scroll-margin-top: calc(var(--top-bar-height) + 0.5rem);
}

.commentRow {
  position: relative;
  display: grid;
  grid-template-columns: var(--avatar) minmax(0, 1fr);
  column-gap: var(--gap);
}

.avatarLink {
  display: inline-flex;
  height: var(--avatar);
  border-radius: var(--radius-full);
  text-decoration: none;
}

/* Follows --avatar, which is smaller on phones. */
.avatarLink :deep(.avatar) {
  width: var(--avatar);
  height: var(--avatar);
  font-size: calc(var(--avatar) * 0.46);
}

/* The line down from a comment's avatar, towards its replies. */
.hasReplies > .commentRow::after {
  content: '';
  position: absolute;
  top: calc(var(--avatar) + 0.3rem);
  bottom: 0;
  left: var(--line-x);
  width: var(--line);
  border-radius: var(--line);
  background-color: var(--thread-line);
  transition: background-color var(--duration-fast) var(--ease-out);
}

/* A strip wider than the line, so it's easy to hit. */
.threadLine,
.parentLine {
  position: absolute;
  z-index: 1;
  width: 1rem;
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  cursor: pointer;
}

.threadLine {
  top: var(--avatar);
  bottom: 0;
  left: calc(var(--line-x) + var(--line) / 2 - 0.5rem);
}

/* Covers the reply's elbow, and the line on past it when more replies follow. */
.parentLine {
  display: none;
  top: calc(-1 * var(--reply-gap));
  left: calc(var(--line-x) + var(--line) / 2 - var(--indent) - 0.5rem);
  height: calc(var(--reply-gap) + var(--avatar) / 2);
}

.replies > .commentThread > .parentLine {
  display: block;
}

.replies > .commentThread:not(:last-of-type) > .parentLine,
.replies > .commentThread:has(~ .seeMoreReplies) > .parentLine {
  height: auto;
  bottom: 0;
}

/* Hovering any part of a comment's line darkens all of it. */
.lineHover > .commentRow::after,
.lineHover > .replies > .commentThread::after {
  background-color: var(--thread-line-hover);
}

.lineHover > .replies > .commentThread::before,
.lineHover > .replies > .seeMoreReplies::before {
  border-color: var(--thread-line-hover);
}

.collapsed > .commentRow::after {
  display: none;
}

/* Stands in for the avatar while the comment is collapsed. */
.expandButton {
  display: inline-grid;
  place-items: center;
  width: var(--avatar);
  height: var(--avatar);
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background-color: var(--fill-capsule);
  color: var(--text-2);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .expandButton:hover {
    background-color: var(--fill-capsule-hover);
    color: var(--text-1);
  }
}

.collapsed .meta {
  opacity: 0.75;
}

.commentBody {
  min-width: 0;
}

/* The name sits level with the middle of the avatar. */
.meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0 0.5rem;
  min-height: var(--avatar);
  font-size: var(--text-footnote);
}

.deletedName {
  font-weight: 600;
  color: var(--text-3);
}

.username {
  font-weight: 600;
  color: var(--text-1);
  text-decoration: none;
  overflow-wrap: anywhere;
}

@media (hover: hover) {
  .username:hover {
    text-decoration: underline;
  }
}

.time {
  color: var(--text-2);
}

.edited {
  color: var(--text-3);
}

/* Stands in for the avatar of a deleted comment's (hidden) author. */
.deletedAvatar {
  width: var(--avatar);
  height: var(--avatar);
  border-radius: var(--radius-full);
  border: 1.5px dashed var(--separator-strong);
}

.deletedContent {
  color: var(--text-3);
}

.editArea {
  margin-top: 0.15rem;
}

.content {
  font-size: var(--text-subhead);
  line-height: 1.5;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.3rem;
}

/* A round icon button the same size as the vote arrows beside it. */
.replyButton {
  display: inline-grid;
  place-items: center;
  width: 1.75rem;
  height: 1.75rem;
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  color: var(--text-2);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .replyButton:hover {
    background-color: var(--fill-hover);
    color: var(--text-1);
  }
}

.replyButton:active,
.replyButton[aria-expanded='true'] {
  background-color: var(--fill-pressed);
  color: var(--text-1);
}

.replyArea {
  margin-top: 0.5rem;
}

.replyLogin {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem 0.75rem;
  font-size: var(--text-footnote);
  color: var(--text-2);
}

.reply-area-enter-active {
  transition:
    opacity var(--duration-base) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.reply-area-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-in-out),
    transform var(--duration-fast) var(--ease-in-out);
}

.reply-area-enter-from,
.reply-area-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

.replies {
  position: relative;
  margin-left: var(--indent);
}

.replies > .commentThread,
.replies > .seeMoreReplies {
  position: relative;
  margin-top: var(--reply-gap);
}

/* An elbow from the parent's line into each reply's avatar. */
.replies > .commentThread::before,
.replies > .seeMoreReplies::before {
  content: '';
  position: absolute;
  top: calc(-1 * var(--reply-gap));
  left: calc(var(--line-x) - var(--indent));
  width: calc(var(--indent) - var(--line-x) - 0.3rem);
  height: calc(var(--reply-gap) + var(--avatar) / 2);
  border-bottom-left-radius: 0.75rem;
  border-left: var(--line) solid var(--thread-line);
  border-bottom: var(--line) solid var(--thread-line);
  pointer-events: none;
  transition: border-color var(--duration-fast) var(--ease-out);
}

.replies > .seeMoreReplies::before {
  height: calc(var(--reply-gap) + 0.875rem);
}

/* The parent's line carries on past each reply to the next. */
.replies > .commentThread:not(:last-of-type)::after,
.replies > .commentThread:has(~ .seeMoreReplies)::after {
  content: '';
  position: absolute;
  top: calc(-1 * var(--reply-gap));
  bottom: 0;
  left: calc(var(--line-x) - var(--indent));
  width: var(--line);
  background-color: var(--thread-line);
  pointer-events: none;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.seeMoreReplies {
  display: inline-flex;
  align-items: center;
  height: 1.75rem;
  padding: 0 0.6rem;
  border-radius: var(--radius-full);
  background-color: var(--fill-capsule);
  color: var(--text-1);
  font-size: var(--text-footnote);
  font-weight: 600;
  text-decoration: none;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .seeMoreReplies:hover {
    background-color: var(--fill-capsule-hover);
  }
}

@media (pointer: coarse) {
  .replyButton {
    width: 2.25rem;
    height: 2.25rem;
    margin: 0 -0.375rem;
  }
}

/* Phones: smaller avatars and indents leave deep threads room to read. */
@media (max-width: 600px) {
  .commentThread {
    --avatar: 24px;
    --gap: 0.6rem;
  }
}
</style>
