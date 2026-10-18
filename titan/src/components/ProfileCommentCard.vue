<script setup lang="ts">
import { computed, onMounted, ref, useTemplateRef } from 'vue'
import ChatCircleIcon from '@/components/icons/ChatCircleIcon.vue'
import ClockIcon from '@/components/icons/ClockIcon.vue'
import UserCircleIcon from '@/components/icons/UserCircleIcon.vue'
import VoteButtons from '@/components/VoteButtons.vue'
import { formatRelativeTime } from '@/utils/relativeTime'
import type { ProfileComment } from '@/types/comment'

const props = defineProps<{
  comment: ProfileComment
}>()

const commentLocation = computed(() => ({
  name: 'post',
  params: { post_id: String(props.comment.post.id), comment_id: String(props.comment.id) },
}))

const isOverflowing = ref(false)
const content = useTemplateRef<HTMLParagraphElement>('content')
onMounted(() => {
  if (content.value) {
    isOverflowing.value = content.value.scrollHeight > content.value.clientHeight
  }
})

const dateCreated = computed(() => new Date(props.comment.inserted_at).toLocaleString())
const postedDate = computed(() => formatRelativeTime(props.comment.inserted_at))
</script>

<template>
  <article class="profileCommentCard">
    <p class="context">
      Commented on
      <router-link class="postTitle" :to="`/post/${comment.post.id}`">{{
        comment.post.title
      }}</router-link>
    </p>

    <div class="metadataContainer">
      <router-link class="metadata username" :to="`/@${comment.user.username}`">
        <UserCircleIcon :size="20" />
        <span>{{ comment.user.username }}</span>
      </router-link>

      <span class="metadata timeUploaded" :title="`Posted at ${dateCreated}`">
        <ClockIcon :size="20" />
        <span>{{ postedDate }}</span>
      </span>
    </div>

    <div class="contentContainer">
      <p ref="content" :class="['content', isOverflowing ? 'isOverflowing' : '']">
        {{ comment.content }}
      </p>

      <router-link v-if="isOverflowing" class="overflowButton" :to="commentLocation"
        >Read more</router-link
      >
    </div>

    <div class="stats">
      <VoteButtons
        :id="comment.id"
        :votes="comment.votes"
        :has-voted="comment.hasVoted"
        type="comment"
      />
      <router-link class="action thread" :to="commentLocation">
        <ChatCircleIcon />
        <span>View thread</span>
      </router-link>
    </div>
  </article>
</template>

<style scoped>
.profileCommentCard {
  border: 1px solid var(--bg-2);
  border-radius: 0.75rem;
  padding: 1rem 1.25rem;
  padding-bottom: 0.65rem;
  max-width: 40rem;
  background-color: var(--bg-sub);
}

.context {
  font-size: 0.9rem;
  color: var(--text-2);
}

.postTitle {
  font-weight: bold;
  text-decoration: none;
}

.postTitle:hover {
  text-decoration: underline;
}

.metadataContainer {
  margin-top: 0.75rem;
  display: flex;
  gap: 1rem;
}

.metadata {
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.2rem;
  text-decoration: none;
}
.metadata span,
.metadata {
  color: var(--text-2);
}

.username {
  cursor: pointer;
}
.username:hover {
  text-decoration: underline;
}

.timeUploaded {
  cursor: default;
}

.contentContainer {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  align-items: flex-start;
}

.content {
  margin-top: 0.5rem;
  line-height: 1.4;
  white-space: pre-wrap;
  max-height: 7rem;
  overflow: hidden;
}

.content.isOverflowing {
  mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 1) -10%, rgba(0, 0, 0, 0));
  -webkit-mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 1) -10%, rgba(0, 0, 0, 0));
}

.overflowButton {
  padding: 0.35rem 0.75rem;
  font-size: 0.9rem;
  border-radius: 10px;
  background: var(--bg-2);
  text-decoration: none;
}

.stats {
  margin-top: 0.65rem;
  display: flex;
}

.action {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 1rem;
}

.thread {
  margin-left: 0.35rem;
  cursor: pointer;
  padding: 0.35rem 0.5rem;
  border-radius: 10px;
  text-decoration: none;
}
.thread:hover {
  background: var(--bg-2);
}
</style>
