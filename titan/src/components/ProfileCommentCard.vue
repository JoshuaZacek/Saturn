<script setup lang="ts">
import { computed } from 'vue'
import ChatCircleIcon from '@/components/icons/ChatCircleIcon.vue'
import VoteButtons from '@/components/VoteButtons.vue'
import { formatRelativeTime } from '@/utils/relativeTime'
import type { ProfileComment } from '@/types/comment'

// A comment on someone's profile: the comment first, then the post it was on.
// The author isn't repeated, since the whole page is theirs.
const props = defineProps<{
  comment: ProfileComment
}>()

const threadLocation = computed(() => ({
  name: 'post',
  params: { post_id: String(props.comment.post.id), comment_id: String(props.comment.id) },
}))

const dateCreated = computed(() => new Date(props.comment.inserted_at).toLocaleString())
const postedDate = computed(() => formatRelativeTime(props.comment.inserted_at))
</script>

<template>
  <article class="commentCard">
    <header class="meta">
      <span class="context">
        On
        <RouterLink class="postLink" :to="`/post/${comment.post.id}`">{{
          comment.post.title
        }}</RouterLink>
      </span>
      <time class="time" :datetime="comment.inserted_at" :title="`Posted ${dateCreated}`">
        {{ postedDate }}
      </time>
    </header>

    <p class="content">{{ comment.content }}</p>

    <footer class="actions">
      <VoteButtons
        :id="comment.id"
        :votes="comment.votes"
        :has-voted="comment.hasVoted"
        type="comment"
      />
      <RouterLink class="threadLink" :to="threadLocation">
        <ChatCircleIcon :size="18" />
        <span>View thread</span>
      </RouterLink>
    </footer>
  </article>
</template>

<style scoped>
.commentCard {
  display: flex;
  flex-direction: column;
  max-width: var(--column-width);
  padding: 0.875rem 1.25rem;
  border-radius: var(--radius-lg);
  background-color: var(--surface);
  box-shadow: var(--shadow-sm);
}

/* The post it was on, and when. */
.meta {
  display: flex;
  align-items: baseline;
  gap: 0.75rem;
  min-width: 0;
  font-size: var(--text-footnote);
  color: var(--text-2);
}

.context {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.postLink {
  color: var(--text-1);
  font-weight: 600;
  text-decoration: none;
}

@media (hover: hover) {
  .postLink:hover {
    text-decoration: underline;
  }
}

.time {
  flex-shrink: 0;
  margin-left: auto;
}

.content {
  margin-top: 0.45rem;
  font-size: var(--text-subhead);
  line-height: 1.5;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 6;
  line-clamp: 6;
  overflow: hidden;
}

.actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.75rem;
}

.threadLink {
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
  text-decoration: none;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.threadLink svg {
  color: var(--text-2);
}

@media (hover: hover) {
  .threadLink:hover {
    background-color: var(--fill-capsule-hover);
  }
}

.threadLink:active {
  background-color: var(--fill-capsule-hover);
}

@media (max-width: 600px) {
  .commentCard {
    padding: 0.8rem 1rem;
  }
}
</style>
