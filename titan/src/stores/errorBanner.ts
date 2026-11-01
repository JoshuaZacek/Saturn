import { ref } from 'vue'
import { defineStore } from 'pinia'

export const GENERIC_ERROR_MESSAGE = 'Sorry, something went wrong.'

// The one thing the person can do about the error, shown as a button in it.
export type ErrorBannerAction = {
  label: string
  run: () => void
}

export const useErrorBannerStore = defineStore('errorBanner', () => {
  const message = ref<string | null>(null)
  const action = ref<ErrorBannerAction | null>(null)

  const show = (
    nextMessage: string = GENERIC_ERROR_MESSAGE,
    nextAction: ErrorBannerAction | null = null,
  ) => {
    message.value = nextMessage
    action.value = nextAction
  }

  const dismiss = () => {
    message.value = null
    action.value = null
  }

  return {
    message,
    action,
    show,
    dismiss,
  }
})
