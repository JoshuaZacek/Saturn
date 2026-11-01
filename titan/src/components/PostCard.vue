<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, ref } from 'vue'
import { useRouter } from 'vue-router'
import ActionMenu, { type ActionMenuItem } from '@/components/ActionMenu.vue'
import CharacterCounter from '@/components/CharacterCounter.vue'
import HoverTooltip from '@/components/HoverTooltip.vue'
import PostImage from '@/components/PostImage.vue'
import RelativeTime from '@/components/RelativeTime.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import VoteButtons from '@/components/VoteButtons.vue'
import ChatCircleIcon from '@/components/icons/ChatCircleIcon.vue'
import DeleteIcon from '@/components/icons/DeleteIcon.vue'
import PencilIcon from '@/components/icons/PencilIcon.vue'
import {
  POST_BODY_MAX_LENGTH,
  POST_TITLE_MAX_LENGTH,
  usePostEditing,
} from '@/composables/usePostEditing'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { formatCompactCount } from '@/utils/formatCount'
import type { Post } from '@/types/post'

const props = defineProps<{
  post: Post
  // The post's own page: an article with the whole text and image, its title
  // as the page heading.
  postPageMode?: boolean
  // Leave out what the page already says: the moon on its own page, the
  // author on their profile.
  hideMoon?: boolean
  hideUser?: boolean
}>()

const emit = defineEmits<{
  deleted: [postId: number]
}>()

const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const isDeleting = ref(false)

// Your own post can be edited in place, like a comment.
const {
  current,
  editedText,
  isEditing,
  isText,
  draftTitle,
  draftBody,
  editError,
  isSaving,
  startEditing,
  cancelEditing,
  saveEdit,
} = usePostEditing(() => props.post)

const titleField = ref<HTMLInputElement | null>(null)
const bodyField = ref<HTMLTextAreaElement | null>(null)
const fieldId = `post-edit-${Math.random().toString(36).slice(2)}`

const growBody = async () => {
  await nextTick()
  const field = bodyField.value
  if (field) {
    field.style.height = 'auto'
    field.style.height = `${field.scrollHeight + 2}px`
  }
}

const openEditor = async () => {
  startEditing()
  await nextTick()
  void growBody()
  const field = titleField.value
  if (field) {
    field.focus()
    field.setSelectionRange(field.value.length, field.value.length)
  }
}

// Escape cancels; Cmd/Ctrl+Enter saves from either field.
const onEditKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    event.preventDefault()
    cancelEditing()
  } else if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
    event.preventDefault()
    void saveEdit()
  }
}

const isOwner = computed(() => authStore.isLoggedIn && props.post.user.id === authStore.user.id)
const postLocation = computed(() => ({
  name: 'post',
  params: { post_id: String(props.post.id) },
}))
const imageURL = computed(() => `${backendUrl}/assets/${props.post.body}`)
const commentLabel = computed(
  () => `${props.post.comments} ${props.post.comments === 1 ? 'comment' : 'comments'}`,
)
const avatarSize = computed(() => (props.postPageMode ? 24 : 20))

// The time sits above the card's link (so it can show its tooltip), and still
// opens the post like the rest of the card.
const onTimeClick = () => {
  if (!props.postPageMode) {
    void router.push(postLocation.value)
  }
}
// A card previews the text as one paragraph; the post page keeps its breaks.
const bodyText = computed(() =>
  props.postPageMode ? current.value.body : current.value.body?.replace(/\s+/g, ' ').trim(),
)

const ownerActions: ActionMenuItem[] = [
  { value: 'edit', label: 'Edit', icon: PencilIcon },
  {
    value: 'delete',
    label: 'Delete',
    icon: DeleteIcon,
    danger: true,
    confirm: {
      title: 'Delete this post?',
      message: "It's removed for everyone. This can't be undone.",
      action: 'Delete',
    },
  },
]

const deletePost = () => {
  if (!backendUrl || isDeleting.value) {
    return
  }

  isDeleting.value = true
  const base = backendUrl.replace(/\/$/, '')

  axios
    .delete(`${base}/post/${props.post.id}`)
    .then(() => {
      isDeleting.value = false
      emit('deleted', props.post.id)
    })
    .catch(() => {
      isDeleting.value = false
      errorBanner.show("Post couldn't be deleted. Please try again.")
    })
}

const onAction = (action: string) => {
  if (action === 'edit') {
    void openEditor()
  } else if (action === 'delete') {
    deletePost()
  }
}
</script>

<template>
  <article class="postCard" :class="{ article: postPageMode }">
    <header class="meta">
      <RouterLink v-if="!hideMoon" class="identity" :to="`/${post.moon.name}`">
        <UserAvatar
          :name="post.moon.name"
          :color="post.moon.avatar_color"
          :image="post.moon.avatar_image"
          shape="tile"
          :size="avatarSize"
        />
        <span class="identityName">/{{ post.moon.name }}</span>
      </RouterLink>
      <RouterLink v-else class="identity" :to="`/@${post.user.username}`">
        <UserAvatar
          :name="post.user.username"
          :color="post.user.avatar_color"
          :image="post.user.avatar_image"
          :size="avatarSize"
        />
        <span class="identityName">{{ post.user.username }}</span>
      </RouterLink>

      <RouterLink v-if="!hideMoon && !hideUser" class="author" :to="`/@${post.user.username}`">
        {{ post.user.username }}
      </RouterLink>

      <span class="when">
        <HoverTooltip v-if="current.edited_at" :text="editedText">
          <span class="edited">edited</span>
        </HoverTooltip>
        <RelativeTime class="time" :datetime="post.inserted_at" @click="onTimeClick" />
      </span>

      <ActionMenu
        v-if="isOwner && !isEditing"
        class="options"
        label="Post options"
        :items="ownerActions"
        :busy="isDeleting"
        @select="onAction"
      />
    </header>

    <form
      v-if="isEditing"
      class="editForm"
      novalidate
      @submit.prevent="saveEdit"
      @keydown="onEditKeydown"
    >
      <div class="formField">
        <div class="labelRow">
          <label class="fieldLabel" :for="`${fieldId}-title`">Title</label>
          <CharacterCounter :text="draftTitle" :max="POST_TITLE_MAX_LENGTH" :show-within="20" />
        </div>
        <input
          :id="`${fieldId}-title`"
          ref="titleField"
          v-model="draftTitle"
          class="field"
          type="text"
          autocomplete="off"
        />
      </div>

      <div v-if="isText" class="formField">
        <div class="labelRow">
          <label class="fieldLabel" :for="`${fieldId}-body`">Text</label>
          <CharacterCounter :text="draftBody" :max="POST_BODY_MAX_LENGTH" />
        </div>
        <textarea
          :id="`${fieldId}-body`"
          ref="bodyField"
          v-model="draftBody"
          class="field editBody"
          rows="4"
          @input="growBody"
        />
      </div>

      <p v-if="editError" class="fieldMessage error" role="alert">{{ editError }}</p>

      <div class="editFooter">
        <SubmitButton variant="secondary" size="sm" @click="cancelEditing">Cancel</SubmitButton>
        <SubmitButton type="submit" size="sm" :loading="isSaving">Save</SubmitButton>
      </div>
    </form>

    <template v-else>
      <h1 v-if="postPageMode" class="title">{{ current.title }}</h1>
      <h2 v-else class="title">
        <RouterLink class="titleLink" :to="postLocation">{{ current.title }}</RouterLink>
      </h2>

      <p v-if="post.type === 'text' && bodyText" class="body">{{ bodyText }}</p>
    </template>

    <PostImage
      v-if="post.type === 'image'"
      class="image"
      :src="imageURL"
      :alt="current.title"
      :width="post.image_width"
      :height="post.image_height"
      :mode="postPageMode ? 'full' : 'preview'"
    />

    <footer v-if="!isEditing" class="actions">
      <VoteButtons :id="post.id" :votes="post.votes" :has-voted="post.hasVoted" type="post" />
      <RouterLink
        v-if="!postPageMode"
        class="comments"
        :to="postLocation"
        :aria-label="commentLabel"
      >
        <ChatCircleIcon :size="18" />
        <span>{{ formatCompactCount(post.comments) }}</span>
      </RouterLink>
    </footer>
  </article>
</template>

<style scoped>
.postCard {
  /* The title's link stretches over the whole card. */
  position: relative;
  display: flex;
  flex-direction: column;
  max-width: var(--column-width);
  padding: 0.875rem 1.25rem;
  border-radius: var(--radius-lg);
  background-color: var(--surface);
  box-shadow: var(--shadow-sm);
  transition: background-color var(--duration-fast) var(--ease-out);
}

/* Moon (or author) on the left, time on the right. */
.meta {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  min-width: 0;
  font-size: var(--text-footnote);
  line-height: 1.3;
  color: var(--text-2);
}

.identity,
.author {
  /* Above the card's link. */
  position: relative;
  z-index: 1;
  min-width: 0;
  text-decoration: none;
}

.identity {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  color: var(--text-1);
  font-weight: 600;
}

.identityName,
.author {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.author {
  color: var(--text-2);
}

@media (hover: hover) {
  .identity:hover .identityName,
  .author:hover {
    text-decoration: underline;
  }
}

/* When, and whether it has been edited since. Above the card's link, for
   their tooltips. */
.when {
  position: relative;
  z-index: 1;
  display: inline-flex;
  align-items: baseline;
  gap: 0.4rem;
  flex-shrink: 0;
  margin-left: auto;
}

.edited {
  color: var(--text-3);
}

/* Editing in place: the title and text as fields, where they were. */
.editForm {
  display: flex;
  flex-direction: column;
  gap: 0.9rem;
  margin-top: 0.75rem;
}

.editBody {
  min-height: 7rem;
  line-height: 1.5;
  resize: none;
  overflow-y: hidden;
}

.editFooter {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}

.postCard:not(.article) .time {
  cursor: pointer;
}

.options {
  flex-shrink: 0;
  margin: -0.25rem -0.4rem -0.25rem -0.2rem;
}

.title {
  margin-top: 0.55rem;
  font-size: var(--text-title-3);
  font-weight: 600;
  line-height: 1.3;
  overflow-wrap: anywhere;
}

.titleLink {
  color: inherit;
  text-decoration: none;
}

.titleLink::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
}

.titleLink:focus-visible {
  outline: none;
}

.postCard:has(.titleLink:focus-visible) {
  outline: 2px solid var(--accent-color);
  outline-offset: 2px;
}

/* A press on the card tints it, like a list row. */
.postCard:has(.titleLink:active) {
  background-color: color-mix(in srgb, var(--surface) 96%, var(--text-1));
}

.body {
  margin-top: 0.3rem;
  font-size: var(--text-subhead);
  line-height: 1.5;
  color: var(--text-2);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  overflow: hidden;
}

.image {
  margin-top: 0.75rem;
}

.actions {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.875rem;
  /* Clicks between the buttons fall through to the card. */
  pointer-events: none;
}

.actions > * {
  pointer-events: auto;
}

.comments {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  height: var(--control-sm);
  padding: 0 0.8rem 0 0.65rem;
  border-radius: var(--radius-full);
  background-color: var(--fill-capsule);
  color: var(--text-1);
  font-size: var(--text-subhead);
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  text-decoration: none;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.comments svg {
  color: var(--text-2);
}

@media (hover: hover) {
  .comments:hover {
    background-color: var(--fill-capsule-hover);
  }
}

.comments:active {
  background-color: var(--fill-capsule-hover);
}

/* The post page: an article on the page itself, not a card. */
.article {
  padding: 0;
  border-radius: 0;
  background: none;
  box-shadow: none;
}

.article .meta {
  font-size: var(--text-subhead);
}

.article .title {
  margin-top: 0.85rem;
  font-size: var(--text-title-1);
  font-weight: 700;
  line-height: 1.2;
  letter-spacing: var(--tracking-tight);
}

.article .body {
  display: block;
  margin-top: 0.75rem;
  font-size: var(--text-reading);
  line-height: 1.6;
  color: var(--text-1);
  overflow: visible;
  -webkit-line-clamp: none;
  line-clamp: none;
}

.article .image {
  margin-top: 1rem;
}

.article .actions {
  margin-top: 1rem;
}

@media (max-width: 600px) {
  .postCard:not(.article) {
    padding: 0.8rem 1rem;
  }
}
</style>
