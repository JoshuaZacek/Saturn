<script setup lang="ts">
import axios from 'axios'
import { watch } from 'vue'
import InfiniteScrollFooter from '@/components/InfiniteScrollFooter.vue'
import PostCard from '@/components/PostCard.vue'
import { usePaginatedList } from '@/composables/usePaginatedList'
import { useErrorBannerStore } from '@/stores/errorBanner'
import type { Post, PostsResponse } from '@/types/post'

const PAGE_SIZE = 10

// Query params for `GET /posts` other than `limit` and `cursor`
// (`sort`, plus optional `time_period`, `moon_id` or `subscribed`).
const props = withDefaults(
  defineProps<{
    params: Record<string, string | number>
    emptyText?: string
  }>(),
  {
    emptyText: 'Hmmm... empty.',
  },
)

const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const errorBanner = useErrorBannerStore()

const { items, isLoading, hasFailed, isEmpty, hasMore, reload, loadMore, retry } =
  usePaginatedList<Post>(
    async (cursor) => {
      if (!backendUrl) {
        throw new Error('VITE_BACKEND_URL is not set')
      }

      const base = backendUrl.replace(/\/$/, '')
      const response = await axios.get<PostsResponse>(`${base}/posts`, {
        params: {
          ...props.params,
          limit: PAGE_SIZE,
          ...(cursor ? { cursor } : {}),
        },
      })

      return { items: response.data.posts, nextCursor: response.data.next_cursor }
    },
    { onError: () => errorBanner.show("Posts couldn't be loaded. Please try again.") },
  )

const removePost = (postId: number) => {
  items.value = items.value.filter((post) => post.id !== postId)
}

watch(
  () => JSON.stringify(props.params),
  () => void reload(),
  { immediate: true },
)
</script>

<template>
  <div class="postFeed">
    <div v-if="items.length > 0" class="posts">
      <PostCard v-for="post in items" :key="post.id" :post="post" @deleted="removePost" />
    </div>

    <InfiniteScrollFooter
      class="footer"
      :loading="isLoading"
      :has-more="hasMore"
      :failed="hasFailed"
      :empty="isEmpty"
      :empty-text="emptyText"
      end-text="You've reached the end."
      @load-more="loadMore"
      @retry="retry"
    />
  </div>
</template>

<style scoped>
.posts {
  display: grid;
  gap: var(--post-feed-gap, 1.5rem);
}

.footer {
  margin-top: 2rem;
}

.postFeed::after {
  content: '';
  display: block;
  height: 5rem;
}
</style>
