<template>
  <main class="formPage">
    <PageHeader title="Create moon" />

    <form class="formCard" novalidate @submit.prevent="submitMoon">
      <div class="formField">
        <div class="labelRow">
          <label class="fieldLabel" for="name">Name</label>
          <CharacterCounter :text="name" :max="NAME_MAX_LENGTH" :show-within="5" />
        </div>
        <div class="prefixField" :class="{ error: nameMessage.tone === 'error' }">
          <span class="prefix" aria-hidden="true">/</span>
          <input
            id="name"
            v-model="name"
            type="text"
            name="name"
            autocomplete="off"
            autocapitalize="off"
            spellcheck="false"
            :aria-invalid="nameMessage.tone === 'error' || undefined"
            aria-describedby="name-message"
            @blur="validateNameNow"
          />
          <InputStatusIndicator :status="indicatorStatus" />
        </div>
        <p id="name-message" class="fieldMessage" :class="nameMessage.tone" aria-live="polite">
          {{ nameMessage.text }}
        </p>
      </div>

      <div class="formFooter">
        <SubmitButton type="submit" size="lg" :loading="isSubmitting">Create moon</SubmitButton>
      </div>
    </form>
  </main>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import CharacterCounter from '@/components/CharacterCounter.vue'
import InputStatusIndicator from '@/components/InputStatusIndicator.vue'
import PageHeader from '@/components/PageHeader.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore } from '@/stores/ui'

type NameStatus = 'idle' | 'checking' | 'available' | 'taken' | 'error'

const NAME_VALIDATION_DELAY_MS = 380
const NAME_PATTERN = /^\w+$/
const NAME_FORMAT_ERROR = 'Moon names can only contain letters, numbers, and underscores.'
const NAME_MAX_LENGTH = 20

const router = useRouter()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const name = ref('')
const isSubmitting = ref(false)
const nameStatus = ref<NameStatus>('idle')

const errors = ref({
  name: '',
})

const indicatorStatus = computed(() => {
  if (nameStatus.value === 'checking') {
    return 'checking'
  }

  return nameStatus.value === 'available' ? 'valid' : null
})

// Under the field: the error if there is one, else whether the name is free,
// else what a moon is and what its name can contain.
const nameMessage = computed(() => {
  if (errors.value.name) {
    return { text: errors.value.name, tone: 'error' }
  }

  if (nameStatus.value === 'taken') {
    return { text: 'This moon name is already taken.', tone: 'error' }
  }

  if (nameStatus.value === 'available') {
    return { text: `/${name.value.trim()} is available.`, tone: 'success' }
  }

  return {
    text: 'A moon is a community for one topic. Names can use letters, numbers and underscores.',
    tone: '',
  }
})

let nameValidationTimeout: ReturnType<typeof setTimeout> | null = null
let nameValidationRequestId = 0
let lastCheckedName: string | null = null
let isCheckInFlight = false

const clearNameValidationTimer = () => {
  if (nameValidationTimeout) {
    clearTimeout(nameValidationTimeout)
    nameValidationTimeout = null
  }
}

const resetNameStatus = () => {
  nameValidationRequestId += 1
  nameStatus.value = 'idle'
}

const isAlreadySettledFor = (moonName: string) =>
  lastCheckedName === moonName &&
  !isCheckInFlight &&
  (nameStatus.value === 'available' || nameStatus.value === 'taken')

const isAlreadyCheckingFor = (moonName: string) => lastCheckedName === moonName && isCheckInFlight

const validateNameNow = async () => {
  if (!backendUrl) {
    clearNameValidationTimer()
    nameStatus.value = 'error'
    return
  }

  const moonName = name.value.trim()

  if (!moonName || !NAME_PATTERN.test(moonName) || moonName.length > NAME_MAX_LENGTH) {
    clearNameValidationTimer()
    resetNameStatus()
    return
  }

  // Avoid re-checking (and re-flashing the spinner) for a name we've already
  // resolved or are already in the middle of resolving, e.g. when the input
  // is blurred right after the debounced check already settled.
  if (isAlreadySettledFor(moonName) || isAlreadyCheckingFor(moonName)) {
    clearNameValidationTimer()
    return
  }

  clearNameValidationTimer()
  lastCheckedName = moonName
  isCheckInFlight = true
  nameStatus.value = 'checking'
  const currentRequestId = ++nameValidationRequestId
  const requestStartedAt = Date.now()

  try {
    const base = backendUrl.replace(/\/$/, '')
    await axios.get(`${base}/moon/${encodeURIComponent(moonName)}`)

    if (currentRequestId !== nameValidationRequestId) {
      return
    }

    await waitForMinimumVisibleTime(requestStartedAt)

    if (currentRequestId !== nameValidationRequestId) {
      return
    }

    nameStatus.value = 'taken'
  } catch (error) {
    if (currentRequestId !== nameValidationRequestId) {
      return
    }

    await waitForMinimumVisibleTime(requestStartedAt)

    if (currentRequestId !== nameValidationRequestId) {
      return
    }

    if (axios.isAxiosError(error) && error.response?.status === 404) {
      nameStatus.value = 'available'
      return
    }

    nameStatus.value = 'error'
  } finally {
    if (currentRequestId === nameValidationRequestId) {
      isCheckInFlight = false
    }
  }
}

const scheduleNameValidation = () => {
  clearNameValidationTimer()

  const moonName = name.value.trim()
  if (!moonName || !NAME_PATTERN.test(moonName) || moonName.length > NAME_MAX_LENGTH) {
    resetNameStatus()
    return
  }

  if (isAlreadySettledFor(moonName)) {
    return
  }

  resetNameStatus()
  nameStatus.value = 'checking'
  nameValidationTimeout = setTimeout(() => {
    void validateNameNow()
  }, NAME_VALIDATION_DELAY_MS)
}

const createEmptyErrors = () => ({
  name: '',
})

const validateForm = async () => {
  const nextErrors = createEmptyErrors()

  let isValid = true
  const moonName = name.value.trim()

  if (!moonName) {
    nextErrors.name = 'Moon name is required'
    isValid = false
  } else if (!NAME_PATTERN.test(moonName)) {
    nextErrors.name = NAME_FORMAT_ERROR
    isValid = false
  } else if (moonName.length > NAME_MAX_LENGTH) {
    nextErrors.name = `Moon name must be ${NAME_MAX_LENGTH} characters or fewer`
    isValid = false
  } else {
    if (nameStatus.value !== 'taken' && nameStatus.value !== 'available') {
      await validateNameNow()
    }

    if (nameStatus.value === 'taken') {
      nextErrors.name = 'This moon name is already taken'
      isValid = false
    }
  }

  return {
    isValid,
    errors: nextErrors,
  }
}

const submitMoon = async () => {
  if (!backendUrl || isSubmitting.value) {
    if (!backendUrl) {
      errorBanner.show()
    }
    return
  }

  isSubmitting.value = true
  const submitStartedAt = Date.now()
  let pendingErrors: ReturnType<typeof createEmptyErrors> | null = null

  try {
    const validationResult = await validateForm()

    if (!validationResult.isValid) {
      await waitForMinimumVisibleTime(submitStartedAt)
      errors.value = validationResult.errors
      return
    }

    const moonName = name.value.trim()
    const base = backendUrl.replace(/\/$/, '')
    const payload = new FormData()
    payload.set('name', moonName)

    await axios.post(`${base}/moon`, payload)

    await waitForMinimumVisibleTime(submitStartedAt)

    await router.push({ name: 'moon', params: { moon: moonName } })
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 400) {
      const responseErrors = error.response.data?.errors
      const nextErrors = createEmptyErrors()

      if (responseErrors?.name?.[0]) {
        nextErrors.name = responseErrors.name[0]
      } else {
        nextErrors.name = `Moon name must be ${NAME_MAX_LENGTH} characters or fewer`
      }

      pendingErrors = nextErrors
      return
    }

    if (axios.isAxiosError(error) && error.response?.status === 403) {
      errorBanner.show('Please log in to create a moon.', {
        label: 'Log in',
        run: () => uiStore.openAuth('login'),
      })
      return
    }

    errorBanner.show("Moon couldn't be created. Please try again.")
  } finally {
    await waitForMinimumVisibleTime(submitStartedAt)

    if (pendingErrors) {
      errors.value = pendingErrors
    }

    isSubmitting.value = false
  }
}

watch(name, () => {
  const moonName = name.value.trim()

  if (moonName && !NAME_PATTERN.test(moonName)) {
    clearNameValidationTimer()
    resetNameStatus()
    errors.value.name = NAME_FORMAT_ERROR
    return
  }

  errors.value.name = ''

  if (moonName.length > NAME_MAX_LENGTH) {
    clearNameValidationTimer()
    resetNameStatus()
    return
  }

  scheduleNameValidation()
})

onBeforeUnmount(() => {
  clearNameValidationTimer()
})
</script>

<style scoped>
.formPage {
  width: 100%;
  max-width: var(--column-width);
}
</style>
