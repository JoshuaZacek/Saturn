<template>
  <main>
    <h1>Create moon</h1>

    <div class="moonSection">
      <form @submit.prevent="submitMoon">
        <section>
          <div class="nameInputRow">
            <span class="namePrefix">/</span>
            <input
              id="name"
              v-model="name"
              class="textInput nameInput"
              type="text"
              name="name"
              autocomplete="off"
              autocapitalize="off"
              spellcheck="false"
              placeholder="Moon name..."
              @blur="validateNameNow"
            />

            <InputStatusIndicator :status="indicatorStatus" />
          </div>

          <p class="feedback info" :class="{ danger: isNameCharacterCountAtLimit }">
            {{ name.length }} / {{ NAME_MAX_LENGTH }}
          </p>

          <p v-if="errors.name" class="feedback error">{{ errors.name }}</p>
          <p v-else-if="nameStatus === 'taken'" class="feedback error">
            This moon name is already taken.
          </p>
        </section>

        <button class="submitButton" type="submit" :disabled="isSubmitting">
          <span class="submitButtonContent">
            <span v-if="isSubmitting" class="submitButtonSpinner">
              <SpinnerLoader
                :size="20"
                bgColor="var(--accent-color)"
                fgColor="var(--accent-text)"
              />
            </span>
            <span style="color: var(--accent-text)">Create moon</span>
          </span>
        </button>
      </form>
    </div>
  </main>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import InputStatusIndicator from '@/components/InputStatusIndicator.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useErrorBannerStore } from '@/stores/errorBanner'

type NameStatus = 'idle' | 'checking' | 'available' | 'taken' | 'error'

const NAME_VALIDATION_DELAY_MS = 380
const NAME_PATTERN = /^\w+$/
const NAME_FORMAT_ERROR = 'Moon names can only contain letters, numbers, and underscores.'
const NAME_MAX_LENGTH = 20

const router = useRouter()
const errorBanner = useErrorBannerStore()
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

const isNameCharacterCountAtLimit = computed(() => name.value.length >= NAME_MAX_LENGTH)

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
      errorBanner.show('Please log in to create a moon.')
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
.moonSection {
  background: var(--bg-sub);
  border: 1px solid var(--bg-2);
  border-radius: 20px;
  padding: 2rem 1.5rem;
  width: 100%;
  margin-top: 2rem;
}

main {
  width: 40rem;
}

h1 {
  margin-bottom: 1.5rem;
}

.nameInputRow {
  width: 100%;
  display: flex;
  align-items: center;
}

.namePrefix {
  color: var(--text-3);
  font-size: 1.75rem;
  line-height: 1;
  margin-right: 0.5rem;
  flex-shrink: 0;
}

.textInput:focus {
  position: relative;
  z-index: 1;
  outline: 2px solid var(--accent-color);
  outline-offset: 1px;
}

.textInput {
  width: 100%;
  border: 1px solid var(--bg-2);
  border-radius: 10px;
  background: transparent;
  color: var(--text-1);
  font-size: 1rem;
  padding: 0.75rem 0.75rem;
  background-color: var(--bg-1);
}

.textInput::placeholder {
  color: var(--text-3);
}

.feedback {
  font-size: 1rem;
  margin-top: 0.5rem;
}

.feedback.info {
  color: var(--text-2);
  position: absolute;
  font-size: 0.8rem;
  margin-top: -1rem;
  margin-left: 39.5rem;
  text-wrap: nowrap;
}

.feedback.info.danger {
  color: var(--text-error);
}

.feedback.error {
  color: var(--text-error);
}

.submitButton {
  margin-top: 2rem;
  width: 100%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 2.75rem;
  border: 1px solid var(--bg-2);
  border-radius: 11px;
  padding: 0 0.75rem;
  background: var(--accent-color);
  font-size: 1rem;
  font-weight: 600;
  line-height: 1;
  cursor: pointer;
  box-sizing: border-box;
}

.submitButtonContent {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  line-height: 1;
}

.submitButtonSpinner {
  width: 20px;
  height: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  overflow: hidden;
}

@media (max-width: 720px) {
  main {
    width: 100%;
    padding: 0 1rem 2rem;
  }
}
</style>
