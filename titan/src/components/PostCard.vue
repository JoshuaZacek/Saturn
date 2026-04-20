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

    <div v-if="post.type == 'text'" class="bodyContainer">
      <p v-if="post.body" :class="['body', isOverflowing ? 'isOverflowing' : '']" ref="body">
        {{ post.body }}
      </p>

      <router-link v-if="isOverflowing" class="overflowButton" :to="`/post/${post.id}`"
        >Read more</router-link
      >
    </div>

    <img loading="lazy" v-if="post.type == 'image'" :src="imageURL" :alt="post.title" />

    <div class="stats">
      <VoteButtons :id="post.id" :votes="post.votes" :hasVoted="post.hasVoted" type="post" />
      <router-link class="action comments" :to="`/post/${post.id}`">
        <ChatCircleIcon />
        <span>{{ post.comments }}</span>
      </router-link>

      <button
        class="action delete"
        v-if="post.user.id == authStore.user.id"
        :disabled="isDeleting"
        @click="deletePost"
      >
        <span class="deleteIconWrap">
          <SpinnerLoader
            v-if="isDeleting"
            bgColor="var(--bg-main)"
            fgColor="var(--text-2)"
            :size="20"
          />
          <DeleteIcon v-else />
        </span>
      </button>
    </div>
  </article>
</template>
<script setup lang="ts">
import axios from 'axios'
import { computed, onMounted, ref, useTemplateRef } from 'vue'
import DeleteIcon from '@/components/icons/DeleteIcon.vue'
import ChatCircleIcon from '@/components/icons/ChatCircleIcon.vue'
import ClockIcon from '@/components/icons/ClockIcon.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import VoteButtons from '@/components/VoteButtons.vue'
import UserCircleIcon from '@/components/icons/UserCircleIcon.vue'
import { useAuthStore } from '@/stores/auth'
import type { Post } from '@/types/post'

const props = defineProps<{
  post: Post
}>()

const emit = defineEmits<{
  deleted: [postId: number]
}>()

const authStore = useAuthStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const isDeleting = ref(false)
const imageURL = computed(() => {
  return `${backendUrl}/assets/${props.post.body}`
})

const deletePost = () => {
  if (!backendUrl || isDeleting.value) {
    return
  }

  isDeleting.value = true
  const base = backendUrl.replace(/\/$/, '')

  axios
    .delete(`${base}/post/${props.post.id}`)
    .then(async () => {
      isDeleting.value = false
      emit('deleted', props.post.id)
    })
    .catch(() => {
      isDeleting.value = false
      alert("Post couldn't be deleted")
    })
}

const isOverflowing = ref(false)
const body = useTemplateRef<HTMLParagraphElement>('body')
onMounted(() => {
  if (body.value) {
    isOverflowing.value = body.value.scrollHeight > body.value.clientHeight
  }
})

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
  background-color: var(--bg-sub);
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
  max-height: 7rem;
  overflow: hidden;
}

.body.isOverflowing {
  mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 1) -10%, rgba(0, 0, 0, 0));
  -webkit-mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 1) -10%, rgba(0, 0, 0, 0));
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
  margin-left: 0.35rem;
  cursor: pointer;
  padding: 0.35rem 0.5rem;
  border-radius: 10px;
  text-decoration: none;
}
.comments:hover {
  background: var(--bg-2);
}

.overflowButton {
  padding: 0.35rem 0.75rem;
  font-size: 0.9rem;
  border-radius: 10px;
  background: var(--bg-2);
  text-decoration: none;
}

.bodyContainer {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  align-items: flex-start;
}

img {
  margin-top: 0.5rem;
  border-radius: 0.5rem;
  height: 10rem;
  border: 1px solid var(--bg-2);
}

.delete {
  cursor: pointer;
  padding: 0.35rem 0.5rem;
  border-radius: 10px;
  text-decoration: none;
  border: none;
  background: var(--bg-main);
  min-width: 34px;
  min-height: 34px;
  justify-content: center;
}

.deleteIconWrap {
  width: 22px;
  height: 22px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.delete:hover {
  background: var(--bg-2);
}

.delete:disabled {
  cursor: default;
}
</style>
