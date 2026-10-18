<script setup lang="ts">
import axios from 'axios'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter, type LocationQueryValue } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'
import InfiniteScrollFooter from '@/components/InfiniteScrollFooter.vue'
import PostCard from '@/components/PostCard.vue'
import ProfileCommentCard from '@/components/ProfileCommentCard.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import { usePaginatedList } from '@/composables/usePaginatedList'
import { notFoundLocation } from '@/router'
import { useErrorBannerStore } from '@/stores/errorBanner'
import type { ProfileComment } from '@/types/comment'
import type { Post } from '@/types/post'
import type {
  ProfileContentResponse,
  ProfileContentType,
  ProfileItem,
  ProfileOverviewEntry,
  ProfileUser,
} from '@/types/profile'

type SortType = 'new' | 'top'

const PAGE_SIZE = 10

const contentTypeOptions: Array<{ label: string; value: ProfileContentType }> = [
  { label: 'Overview', value: 'overview' },
  { label: 'Posts', value: 'posts' },
  { label: 'Comments', value: 'comments' },
]
const sortOptions: Array<{ label: string; value: SortType }> = [
  { label: 'New', value: 'new' },
  { label: 'Top', value: 'top' },
]

const getSingleQueryValue = (value: LocationQueryValue | LocationQueryValue[] | undefined) =>
  Array.isArray(value) ? value[0] : value

const route = useRoute()
const router = useRouter()
const errorBanner = useErrorBannerStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const username = computed(() => String(route.params.username))
const contentType = computed<ProfileContentType>(() => {
  const tab = getSingleQueryValue(route.query.tab)
  return tab === 'posts' || tab === 'comments' ? tab : 'overview'
})
const sort = computed<SortType>(() =>
  getSingleQueryValue(route.query.sort) === 'top' ? 'top' : 'new',
)

const user = ref<ProfileUser | null>(null)
const isLoadingUser = ref(true)

const getItemKey = (item: ProfileItem) =>
  item.kind === 'post' ? `post-${item.post.id}` : `comment-${item.comment.id}`

const fetchContent = async <T,>(type: ProfileContentType, cursor: string | null) => {
  if (!backendUrl || !user.value) {
    throw new Error('Profile content requested before the user loaded')
  }

  const base = backendUrl.replace(/\/$/, '')
  const response = await axios.get<ProfileContentResponse<T>>(`${base}/profile/${type}`, {
    params: {
      user_id: user.value.id,
      sort: sort.value,
      limit: PAGE_SIZE,
      ...(cursor ? { cursor } : {}),
    },
  })

  return response.data
}

const {
  items,
  isLoading,
  hasFailed,
  isEmpty,
  hasMore,
  reload: loadContent,
  loadMore,
  retry,
} = usePaginatedList<ProfileItem>(
  async (cursor) => {
    const type = contentType.value

    if (type === 'posts') {
      const data = await fetchContent<Post>(type, cursor)
      return {
        items: data.content.map((post): ProfileItem => ({ kind: 'post', post })),
        nextCursor: data.next_cursor,
      }
    }

    if (type === 'comments') {
      const data = await fetchContent<ProfileComment>(type, cursor)
      return {
        items: data.content.map((comment): ProfileItem => ({ kind: 'comment', comment })),
        nextCursor: data.next_cursor,
      }
    }

    const data = await fetchContent<ProfileOverviewEntry>(type, cursor)
    return {
      items: data.content.map(
        (entry): ProfileItem =>
          entry.contentType === 'post'
            ? { kind: 'post', post: entry }
            : { kind: 'comment', comment: entry },
      ),
      nextCursor: data.next_cursor,
    }
  },
  {
    // Overview pages are cut by row number, which can repeat an entry across pages.
    getKey: getItemKey,
    onError: () => errorBanner.show("This profile couldn't be loaded. Please try again."),
  },
)

const removePost = (postId: number) => {
  items.value = items.value.filter((item) => item.kind !== 'post' || item.post.id !== postId)
}

const onContentTypeChange = (value: string) => {
  void router.push({
    query: { ...route.query, tab: value === 'overview' ? undefined : value },
  })
}

const onSortChange = (value: string) => {
  void router.push({
    query: { ...route.query, sort: value === 'new' ? undefined : value },
  })
}

let userRequestId = 0

const loadUser = async (name: string) => {
  const currentRequestId = ++userRequestId
  user.value = null
  isLoadingUser.value = true

  try {
    if (!backendUrl) {
      throw new Error('VITE_BACKEND_URL is not set')
    }

    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.get<ProfileUser>(`${base}/user/${encodeURIComponent(name)}`)

    if (currentRequestId !== userRequestId) {
      return
    }

    user.value = response.data
  } catch (err) {
    if (currentRequestId !== userRequestId) {
      return
    }

    if (axios.isAxiosError(err) && err.response?.status === 404) {
      void router.replace(notFoundLocation(route))
    } else {
      errorBanner.show("This profile couldn't be loaded. Please try again.")
    }
  } finally {
    if (currentRequestId === userRequestId) {
      isLoadingUser.value = false
    }
  }
}

// The component is reused when navigating between profiles, so reload on param change.
watch(username, (name) => void loadUser(name), { immediate: true })
watch([() => user.value?.id, contentType, sort], () => {
  if (user.value) {
    void loadContent()
  }
})
</script>

<template>
  <main>
    <h1>@{{ username }}</h1>

    <template v-if="user">
      <SegmentedControl
        label="Profile content"
        :model-value="contentType"
        :options="contentTypeOptions"
        @update:model-value="onContentTypeChange"
      />

      <CustomSelect
        label="Sort by"
        :model-value="sort"
        :options="sortOptions"
        @update:model-value="onSortChange"
      />

      <div v-if="items.length > 0" class="profileContent">
        <template v-for="item in items" :key="getItemKey(item)">
          <PostCard v-if="item.kind === 'post'" :post="item.post" @deleted="removePost" />
          <ProfileCommentCard v-else :comment="item.comment" />
        </template>
      </div>

      <InfiniteScrollFooter
        class="footer"
        :loading="isLoading"
        :has-more="hasMore"
        :failed="hasFailed"
        :empty="isEmpty"
        empty-text="Hmmm... empty."
        end-text="You've reached the end."
        @load-more="loadMore"
        @retry="retry"
      />
    </template>
    <div v-else-if="isLoadingUser" class="profileLoading" aria-live="polite" aria-busy="true">
      <SpinnerLoader :size="30" fgColor="var(--text-3)" />
    </div>
  </main>
</template>

<style scoped>
main {
  width: 40rem;
}

h1 {
  margin-bottom: 1.5rem;
  overflow-wrap: anywhere;
}

.profileContent {
  margin-top: 2rem;
  display: grid;
  gap: 1.5rem;
}

.footer {
  margin-top: 2rem;
}

.profileLoading {
  display: flex;
  justify-content: center;
  margin-top: 2rem;
}

main::after {
  content: '';
  display: block;
  height: 5rem;
}
</style>
