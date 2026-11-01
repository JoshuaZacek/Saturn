import axios from 'axios'
import { computed, ref } from 'vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useErrorBannerStore } from '@/stores/errorBanner'
import type { Post } from '@/types/post'
import { countCharacters } from '@/utils/characterCount'
import { formatPreciseTime } from '@/utils/relativeTime'

export const POST_TITLE_MAX_LENGTH = 100
export const POST_BODY_MAX_LENGTH = 5000
const SAVE_FAILED = "Your post couldn't be saved. Please try again."

// Editing your own post where it's shown, like editing a comment: its title,
// and a text post's text (an image post keeps its image). `current` is the post
// with any change made here.
export const usePostEditing = (post: () => Post) => {
  const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
  const errorBanner = useErrorBannerStore()

  const changes = ref<Partial<Post>>({})
  const current = computed(() => ({ ...post(), ...changes.value }))

  const editedText = computed(() =>
    current.value.edited_at ? `Edited ${formatPreciseTime(current.value.edited_at)}` : '',
  )

  const isEditing = ref(false)
  const draftTitle = ref('')
  const draftBody = ref('')
  const editError = ref('')
  const isSaving = ref(false)
  const isText = computed(() => current.value.type === 'text')

  const startEditing = () => {
    draftTitle.value = current.value.title
    draftBody.value = isText.value ? (current.value.body ?? '') : ''
    editError.value = ''
    isEditing.value = true
  }

  const cancelEditing = () => {
    isEditing.value = false
    editError.value = ''
  }

  const saveEdit = async () => {
    if (isSaving.value) {
      return
    }

    const title = draftTitle.value.trim()
    const body = draftBody.value.trim()

    if (!title) {
      editError.value = 'Title is required'
    } else if (countCharacters(title) > POST_TITLE_MAX_LENGTH) {
      editError.value = `Title must be ${POST_TITLE_MAX_LENGTH} characters or fewer`
    } else if (isText.value && !body) {
      editError.value = 'Text is required'
    } else if (isText.value && countCharacters(body) > POST_BODY_MAX_LENGTH) {
      editError.value = `Text must be ${POST_BODY_MAX_LENGTH} characters or fewer`
    } else {
      editError.value = ''
    }

    if (editError.value) {
      return
    }

    // Nothing changed: nothing to save, and it isn't marked as edited.
    if (title === current.value.title && (!isText.value || body === current.value.body)) {
      cancelEditing()
      return
    }

    isSaving.value = true
    const startedAt = Date.now()

    try {
      const response = await axios.patch<Post>(
        `${(backendUrl ?? '').replace(/\/$/, '')}/post/${current.value.id}`,
        isText.value ? { title, body } : { title },
      )
      await waitForMinimumVisibleTime(startedAt)
      changes.value = {
        title: response.data.title,
        body: response.data.body,
        edited_at: response.data.edited_at,
      }
      isEditing.value = false
      errorBanner.dismissMessage(SAVE_FAILED)
    } catch (err) {
      await waitForMinimumVisibleTime(startedAt)
      const errors = axios.isAxiosError(err) ? err.response?.data?.errors : undefined
      const fieldError = errors?.title?.[0] ?? errors?.body?.[0]

      // A problem with what they wrote goes under the fields; anything else
      // (offline, server error) is a failed request, for the error banner.
      // The editor stays open either way, so nothing is lost.
      if (fieldError) {
        editError.value = fieldError
      } else {
        errorBanner.show(SAVE_FAILED)
      }
    } finally {
      isSaving.value = false
    }
  }

  return {
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
  }
}
