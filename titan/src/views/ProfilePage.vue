<script setup lang="ts">
import axios from 'axios'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter, type LocationQueryValue } from 'vue-router'
import AnimatedList from '@/components/AnimatedList.vue'
import AvatarEditor from '@/components/AvatarEditor.vue'
import EmptyState from '@/components/EmptyState.vue'
import EntityHeader from '@/components/EntityHeader.vue'
import HoverTooltip from '@/components/HoverTooltip.vue'
import InfiniteScrollFooter from '@/components/InfiniteScrollFooter.vue'
import PostCard from '@/components/PostCard.vue'
import ProfileCommentCard from '@/components/ProfileCommentCard.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import ClockIcon from '@/components/icons/ClockIcon.vue'
import { usePaginatedList } from '@/composables/usePaginatedList'
import { notFoundLocation } from '@/router'
import { useAuthStore } from '@/stores/auth'
import { useAvatarStore } from '@/stores/avatars'
import { useErrorBannerStore } from '@/stores/errorBanner'
import type { ProfileComment } from '@/types/comment'
import type { Post } from '@/types/post'
import type { AvatarFields } from '@/utils/avatar'
import { formatMonthYear, formatPreciseTime } from '@/utils/relativeTime'
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
const emptyTitles: Record<ProfileContentType, string> = {
  overview: 'Nothing here yet',
  posts: 'No posts yet',
  comments: 'No comments yet',
}

const getSingleQueryValue = (value: LocationQueryValue | LocationQueryValue[] | undefined) =>
  Array.isArray(value) ? value[0] : value

const route = useRoute()
const router = useRouter()
const errorBanner = useErrorBannerStore()
const authStore = useAuthStore()
const avatarStore = useAvatarStore()
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
const joinedText = computed(() =>
  user.value ? `Joined ${formatMonthYear(user.value.inserted_at)}` : '',
)
const joinedAtText = computed(() =>
  user.value ? `Joined ${formatPreciseTime(user.value.inserted_at)}` : '',
)

// Your own profile: your picture can be changed from here (and from Settings).
const isOwnProfile = computed(
  () => !!user.value && authStore.isLoggedIn && user.value.id === authStore.user.id,
)
const isEditingAvatar = ref(false)

const onAvatarSaved = (avatar: AvatarFields) => {
  isEditingAvatar.value = false
  if (!user.value) {
    return
  }

  user.value = { ...user.value, ...avatar }
  authStore.changeAvatar(avatar)
  avatarStore.change('user', user.value.username, avatar)
}

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
    // Overview pages are cut by row number, so an entry can repeat across pages
    // when new posts or comments arrive between page loads.
    getKey: getItemKey,
    onError: () => errorBanner.show("This profile couldn't be loaded. Please try again."),
  },
)

const removePost = (postId: number) => {
  items.value = items.value.filter((item) => item.kind !== 'post' || item.post.id !== postId)
}

const removeComment = (commentId: number) => {
  items.value = items.value.filter(
    (item) => item.kind !== 'comment' || item.comment.id !== commentId,
  )
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
    // For the sidebar's "Currently viewing" row.
    avatarStore.remember('user', response.data.username, response.data)
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
  <main class="profilePage">
    <EntityHeader
      :name="username"
      :title="`@${username}`"
      kind="user"
      :avatar="user"
      :editable="isOwnProfile"
      @edit-avatar="isEditingAvatar = true"
    >
      <template #meta>
        <!-- Kept in the layout while loading, so the header doesn't change height. -->
        <HoverTooltip :text="joinedAtText">
          <span class="metaItem" :class="{ pending: !user }" :aria-hidden="!user">
            <ClockIcon :size="16" />
            <span>{{ joinedText || 'Joined' }}</span>
          </span>
        </HoverTooltip>
      </template>
    </EntityHeader>

    <div class="contentArea">
      <div v-if="user" class="toolbar">
        <SegmentedControl
          size="sm"
          label="Profile content"
          :model-value="contentType"
          :options="contentTypeOptions"
          @update:model-value="onContentTypeChange"
        />
        <SegmentedControl
          size="sm"
          label="Sort"
          :model-value="sort"
          :options="sortOptions"
          @update:model-value="onSortChange"
        />
      </div>

      <template v-if="user">
        <AnimatedList v-if="items.length > 0" class="profileContent">
          <div v-for="item in items" :key="getItemKey(item)">
            <PostCard
              v-if="item.kind === 'post'"
              :post="item.post"
              hide-user
              @deleted="removePost"
            />
            <ProfileCommentCard v-else :comment="item.comment" @removed="removeComment" />
          </div>
        </AnimatedList>

        <EmptyState v-if="isEmpty" :title="emptyTitles[contentType]" />

        <InfiniteScrollFooter
          class="footer"
          :loading="isLoading"
          :has-more="hasMore"
          :failed="hasFailed"
          @load-more="loadMore"
          @retry="retry"
        />
      </template>
      <div v-else-if="isLoadingUser" class="profileLoading" aria-live="polite" aria-busy="true">
        <SpinnerLoader :size="28" fg-color="var(--text-3)" />
      </div>
    </div>

    <AvatarEditor
      v-if="user && isOwnProfile"
      :open="isEditingAvatar"
      kind="user"
      :name="user.username"
      :avatar="user"
      endpoint="/user/avatar"
      @close="isEditingAvatar = false"
      @saved="onAvatarSaved"
    />
  </main>
</template>

<style scoped>
.profilePage {
  width: 100%;
  max-width: var(--column-width);
}

.metaItem {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.metaItem svg {
  color: var(--text-3);
}

.metaItem.pending {
  visibility: hidden;
}

/* Their posts and comments, set apart from the header by a hairline. */
.contentArea {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--separator);
}

/* What to show on the left, its order on the right. */
.toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}

.profileContent {
  margin-top: 1.25rem;
  display: grid;
  /* Can shrink below its content, so a comment's one-line post title is cut
     short (…) instead of widening the page on phones. */
  grid-template-columns: minmax(0, 1fr);
  gap: 1rem;
}

/* The footer is an invisible scroll sentinel until it shows a spinner or retry. */
.footer:has(> :not(.sentinel)) {
  margin-top: 1.5rem;
}

.profileLoading {
  display: flex;
  justify-content: center;
  margin-top: 2.5rem;
}

.contentArea::after {
  content: '';
  display: block;
  height: 5rem;
}
</style>
