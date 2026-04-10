<template>
  <article class="postCard">
    <div class="metadataContainer">
      <router-link class="metadata moon" :to="`/${post.moon.name}`"
        >/{{ post.moon.name }}</router-link
      >

      <router-link class="metadata username" :to="`/@${post.user.username}`">
        <UserCircleIcon :size="20" />
        <span>{{ post.user.username }}</span>
      </router-link>

      <span class="metadata timeUploaded" :title="`Posted at ${dateCreated}`">
        <ClockIcon :size="20" />
        <span>{{ postedDate }}</span>
      </span>
    </div>

    <h2 class="title">{{ post.title }}</h2>
    <p v-if="post.body" class="body">{{ post.body }}</p>

    <div class="stats">
      <VoteButtons :id="post.id" :votes="post.votes" :hasVoted="post.hasVoted" type="post" />
      <router-link class="action comments" :to="`/post/${post.id}`">
        <ChatCircleIcon />
        <span>{{ post.comments }}</span>
      </router-link>
    </div>
  </article>
</template>
<script setup lang="ts">
import { computed } from 'vue'
import ChatCircleIcon from '@/components/icons/ChatCircleIcon.vue'
import ClockIcon from '@/components/icons/ClockIcon.vue'
import VoteButtons from '@/components/VoteButtons.vue'
import UserCircleIcon from '@/components/icons/UserCircleIcon.vue'
import type { Post } from '@/types/post'

const props = defineProps<{
  post: Post
}>()

const dateCreated = computed(() => {
  return new Date(props.post.inserted_at).toLocaleString()
})

const postedDate = computed(() => {
  const date = new Date(props.post.inserted_at)
  const now = Date.now()

  if (Number.isNaN(date.getTime())) {
    return ''
  }

  const diffSeconds = Math.max(1, Math.floor((now - date.getTime()) / 1000))

  if (diffSeconds < 60) {
    return `${diffSeconds}s ago`
  }

  const diffMinutes = Math.floor(diffSeconds / 60)
  if (diffMinutes < 60) {
    return `${diffMinutes}m ago`
  }

  const diffHours = Math.floor(diffMinutes / 60)
  if (diffHours < 24) {
    return `${diffHours}h ago`
  }

  const diffDays = Math.floor(diffHours / 24)
  if (diffDays < 30) {
    return `${diffDays}d ago`
  }

  const diffMonths = Math.floor(diffDays / 30)
  if (diffMonths < 12) {
    return `${diffMonths}mo ago`
  }

  const diffYears = Math.floor(diffDays / 365)
  return `${diffYears}y ago`
})
</script>

<style scoped>
.postCard {
  border: 1px solid var(--bg-2);
  border-radius: 0.75rem;
  padding: 1rem 1.25rem;
  padding-bottom: 0.65rem;
  max-width: 40rem;
}

.metadataContainer {
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

.title {
  margin-top: 1rem;
  font-size: 1.25rem;
}

.body {
  margin-top: 0.25rem;
  line-height: 1.4;
  white-space: pre-wrap;
}

.stats {
  margin-top: 0.65rem;
  display: flex;
  gap: 0.5rem;
}

.action {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 1rem;
}

.username,
.moon {
  cursor: pointer;
}
.username:hover,
.moon:hover {
  text-decoration: underline;
}

.timeUploaded {
  cursor: default;
}

.comments {
  cursor: pointer;
  padding: 0.35rem 0.5rem;
  border-radius: 10px;
  text-decoration: none;
}
.comments:hover {
  background: var(--bg-2);
}
</style>
