import axios from 'axios'
import { computed, ref } from 'vue'
import type { ActionMenuItem } from '@/components/ActionMenu.vue'
import DeleteIcon from '@/components/icons/DeleteIcon.vue'
import PencilIcon from '@/components/icons/PencilIcon.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import type { Comment } from '@/types/comment'
import { COMMENT_MAX_LENGTH, countCharacters } from '@/utils/characterCount'
import { formatPreciseTime } from '@/utils/relativeTime'

const SAVE_FAILED = "Your comment couldn't be saved. Please try again."

// Editing and deleting your own comment, wherever it's shown. `current` is the
// comment with any change made here. A comment with replies stays as a
// placeholder when deleted; one without is gone, and `onRemoved` says so.
export const useCommentEditing = <T extends Comment>(comment: () => T, onRemoved: () => void) => {
  const authStore = useAuthStore()
  const errorBanner = useErrorBannerStore()
  const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

  const changes = ref<Partial<Comment>>({})
  const current = computed(() => ({ ...comment(), ...changes.value }) as T)

  const isOwner = computed(
    () =>
      authStore.isLoggedIn &&
      !current.value.deleted &&
      current.value.user?.id === authStore.user.id,
  )

  const editedText = computed(() =>
    current.value.edited_at ? `Edited ${formatPreciseTime(current.value.edited_at)}` : '',
  )

  const isEditing = ref(false)
  const draft = ref('')
  const editError = ref('')
  const isSaving = ref(false)
  const isDeleting = ref(false)

  const apiBase = () => (backendUrl ?? '').replace(/\/$/, '')

  const startEditing = () => {
    draft.value = current.value.content
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

    const content = draft.value.trim()
    if (!content) {
      editError.value = 'Comment cannot be empty'
      return
    }

    if (countCharacters(content) > COMMENT_MAX_LENGTH) {
      editError.value = `Comment must be ${COMMENT_MAX_LENGTH} characters or fewer`
      return
    }

    // Nothing changed: nothing to save, and it isn't marked as edited.
    if (content === current.value.content) {
      cancelEditing()
      return
    }

    isSaving.value = true
    editError.value = ''
    const startedAt = Date.now()

    try {
      const response = await axios.patch<Comment>(`${apiBase()}/comment/${current.value.id}`, {
        content,
      })
      await waitForMinimumVisibleTime(startedAt)
      changes.value = {
        ...changes.value,
        content: response.data.content,
        edited_at: response.data.edited_at,
      }
      isEditing.value = false
      errorBanner.dismissMessage(SAVE_FAILED)
    } catch (err) {
      await waitForMinimumVisibleTime(startedAt)
      const fieldError = axios.isAxiosError(err) && err.response?.data?.errors?.content?.[0]

      // A problem with the text goes under it; a failed request goes in the
      // error banner. The editor stays open either way.
      if (fieldError) {
        editError.value = fieldError
      } else {
        errorBanner.show(SAVE_FAILED)
      }
    } finally {
      isSaving.value = false
    }
  }

  const remove = async () => {
    if (isDeleting.value) {
      return
    }

    isDeleting.value = true
    const startedAt = Date.now()

    try {
      const response = await axios.delete<{ id: number; kept: boolean }>(
        `${apiBase()}/comment/${current.value.id}`,
      )
      await waitForMinimumVisibleTime(startedAt)

      if (response.data.kept) {
        changes.value = { deleted: true, content: '', user: null, edited_at: null }
      } else {
        onRemoved()
      }
    } catch {
      await waitForMinimumVisibleTime(startedAt)
      errorBanner.show("Comment couldn't be deleted. Please try again.")
    } finally {
      isDeleting.value = false
    }
  }

  const ownerActions: ActionMenuItem[] = [
    { value: 'edit', label: 'Edit', icon: PencilIcon },
    {
      value: 'delete',
      label: 'Delete',
      icon: DeleteIcon,
      danger: true,
      confirm: {
        title: 'Delete this comment?',
        message: "It's removed for everyone. This can't be undone.",
        action: 'Delete',
      },
    },
  ]

  const onOwnerAction = (action: string) => {
    if (action === 'edit') {
      startEditing()
    } else if (action === 'delete') {
      void remove()
    }
  }

  return {
    current,
    isOwner,
    editedText,
    isEditing,
    draft,
    editError,
    isSaving,
    isDeleting,
    cancelEditing,
    saveEdit,
    ownerActions,
    onOwnerAction,
  }
}
