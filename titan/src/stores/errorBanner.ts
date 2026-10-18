import { ref } from 'vue'
import { defineStore } from 'pinia'

export const GENERIC_ERROR_MESSAGE = 'Sorry, something went wrong.'

export const useErrorBannerStore = defineStore('errorBanner', () => {
  const message = ref<string | null>(null)

  const show = (nextMessage: string = GENERIC_ERROR_MESSAGE) => {
    message.value = nextMessage
  }

  const dismiss = () => {
    message.value = null
  }

  return {
    message,
    show,
    dismiss,
  }
})
