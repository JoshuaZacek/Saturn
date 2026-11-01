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

  // Takes down this message, if it's the one showing: once a retry works, its
  // earlier failure no longer applies (and any other error still does).
  const dismissMessage = (text: string) => {
    if (message.value === text) {
      dismiss()
    }
  }

  return {
    message,
    action,
    show,
    dismiss,
    dismissMessage,
  }
})
