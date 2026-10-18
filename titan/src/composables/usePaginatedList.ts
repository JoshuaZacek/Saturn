import { computed, ref, type Ref } from 'vue'

export interface Page<T> {
  items: T[]
  nextCursor: string | null
}

type Status = 'idle' | 'loading' | 'loaded' | 'error'

// Cursor-paginated list state shared by the feeds, profile and comments.
// `reload` starts over from the first page; responses from a superseded
// `reload` are dropped, so switching sort/filter mid-request can't mix results.
// With `getKey`, items already in the list are skipped when appending a page.
export const usePaginatedList = <T>(
  fetchPage: (cursor: string | null) => Promise<Page<T>>,
  options: { onError?: (error: unknown) => void; getKey?: (item: T) => string | number } = {},
) => {
  const items = ref([]) as Ref<T[]>
  const nextCursor = ref<string | null>(null)
  const status = ref<Status>('idle')
  const isLoadingMore = ref(false)
  const loadMoreFailed = ref(false)
  let requestId = 0

  const reload = async () => {
    const currentRequestId = ++requestId
    items.value = []
    nextCursor.value = null
    status.value = 'loading'
    isLoadingMore.value = false
    loadMoreFailed.value = false

    try {
      const page = await fetchPage(null)
      if (currentRequestId !== requestId) {
        return
      }

      items.value = page.items
      nextCursor.value = page.nextCursor
      status.value = 'loaded'
    } catch (error) {
      if (currentRequestId !== requestId) {
        return
      }

      status.value = 'error'
      options.onError?.(error)
    }
  }

  const withoutExisting = (pageItems: T[], getKey: (item: T) => string | number) => {
    const existingKeys = new Set(items.value.map(getKey))
    return pageItems.filter((item) => !existingKeys.has(getKey(item)))
  }

  const loadMore = async () => {
    if (status.value !== 'loaded' || isLoadingMore.value || !nextCursor.value) {
      return
    }

    const currentRequestId = requestId
    isLoadingMore.value = true
    loadMoreFailed.value = false

    try {
      const page = await fetchPage(nextCursor.value)
      if (currentRequestId !== requestId) {
        return
      }

      const newItems = options.getKey ? withoutExisting(page.items, options.getKey) : page.items

      items.value.push(...newItems)
      nextCursor.value = page.nextCursor
    } catch (error) {
      if (currentRequestId !== requestId) {
        return
      }

      loadMoreFailed.value = true
      options.onError?.(error)
    } finally {
      if (currentRequestId === requestId) {
        isLoadingMore.value = false
      }
    }
  }

  const retry = () => (status.value === 'error' ? reload() : loadMore())

  const isLoading = computed(() => status.value === 'loading' || isLoadingMore.value)
  const hasFailed = computed(() => status.value === 'error' || loadMoreFailed.value)
  const isEmpty = computed(() => status.value === 'loaded' && items.value.length === 0)
  const hasMore = computed(() => status.value === 'loaded' && nextCursor.value !== null)

  return {
    items,
    status,
    isLoadingMore,
    loadMoreFailed,
    isLoading,
    hasFailed,
    isEmpty,
    hasMore,
    reload,
    loadMore,
    retry,
  }
}
