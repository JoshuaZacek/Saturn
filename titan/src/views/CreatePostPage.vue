<template>
  <main>
    <h1>Create post</h1>

    <SegmentedControl v-model="postMode" :options="postModeOptions" />

    <div class="postSection">
      <section class="moonSection">
        <div class="moonInputRow">
          <div class="moonCombobox">
            <input
              id="moon"
              v-model="moonInput"
              class="textInput moonInput"
              type="text"
              name="moon"
              role="combobox"
              aria-autocomplete="list"
              aria-controls="moonSuggestions"
              :aria-expanded="showMoonSuggestions"
              :aria-activedescendant="
                showMoonSuggestions && highlightedSuggestion >= 0
                  ? `moonSuggestion-${moonSuggestions[highlightedSuggestion]?.id}`
                  : undefined
              "
              autocomplete="off"
              autocapitalize="off"
              spellcheck="false"
              placeholder="Moon..."
              @focus="isMoonInputFocused = true"
              @blur="onMoonInputBlur"
              @keydown="onMoonInputKeydown"
            />

            <ul
              v-show="showMoonSuggestions"
              id="moonSuggestions"
              class="moonSuggestions"
              role="listbox"
              aria-label="Moon suggestions"
            >
              <li
                v-for="(suggestion, index) in moonSuggestions"
                :id="`moonSuggestion-${suggestion.id}`"
                :key="suggestion.id"
                role="option"
                :aria-selected="index === highlightedSuggestion"
                :class="{ highlighted: index === highlightedSuggestion }"
                @mousedown.prevent="selectMoonSuggestion(suggestion)"
                @mousemove="highlightedSuggestion = index"
              >
                /{{ suggestion.name }}
              </li>
            </ul>
          </div>

          <span v-if="moonStatus === 'checking'" class="moonInputSpinner" aria-live="polite">
            <SpinnerLoader :size="20" bgColor="var(--bg-sub)" fgColor="var(--text-3)" />
          </span>

          <span v-else-if="moonStatus === 'exists'" class="moonInputSpinner" aria-live="polite">
            <CheckIcon :size="20" color="var(--vote-up)" />
          </span>
        </div>

        <p v-if="errors.moon" class="feedback error">{{ errors.moon }}</p>
        <p v-else-if="moonStatus === 'missing'" class="feedback error">This moon does not exist.</p>
      </section>

      <section>
        <input
          id="title"
          v-model="title"
          class="textInput titleInput"
          type="text"
          name="title"
          autocomplete="off"
          placeholder="Title..."
        />
        <p class="feedback info" :class="{ danger: isTitleCharacterCountAtLimit }">
          {{ title.length }} / {{ TITLE_MAX_LENGTH }}
        </p>
      </section>

      <form @submit.prevent="submitPost">
        <section v-if="postMode === 'text'" class="section">
          <textarea
            id="body"
            v-model="body"
            ref="bodyTextArea"
            class="textArea"
            name="body"
            rows="3"
            placeholder="Text..."
            @input="autoGrowBody"
          />

          <p class="feedback info" :class="{ danger: isBodyCharacterCountAtLimit }">
            {{ body.length }} / {{ BODY_MAX_LENGTH }}
          </p>

          <p v-if="errors.title" class="feedback error">{{ errors.title }}</p>
          <p v-if="errors.body" class="feedback error">{{ errors.body }}</p>
        </section>

        <section v-else class="section">
          <div
            class="dropzone"
            :class="{ dragActive: isDragActive }"
            @dragenter.prevent="onDragEnter"
            @dragover.prevent="onDragOver"
            @dragleave.prevent="onDragLeave"
            @drop.prevent="onDrop"
          >
            <input
              ref="fileInput"
              class="fileInput"
              type="file"
              accept="image/png,image/jpeg,image/gif"
              @change="onFileChange"
              tabindex="-1"
            />

            <p class="dropzonePrimary">
              {{ selectedFile ? selectedFile.name : 'Drag and drop image here' }}
            </p>
            <p class="dropzoneSecondary">
              or
              <button type="button" class="browseButton" @click="openFilePicker">
                choose image
              </button>
              (.jpg, .jpeg, .png, .gif) (max 15 MB)
            </p>
          </div>

          <p v-if="errors.file" class="feedback error">{{ errors.file }}</p>
          <p v-if="errors.title" class="feedback error">{{ errors.title }}</p>
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
            <span style="color: var(--accent-text)">Submit post</span>
          </span>
        </button>
      </form>
    </div>
  </main>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import CheckIcon from '@/components/icons/CheckIcon.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useErrorBannerStore } from '@/stores/errorBanner'

type PostMode = 'text' | 'image'
type MoonStatus = 'idle' | 'checking' | 'exists' | 'missing' | 'error'
type MoonSuggestion = {
  id: number
  name: string
}
type MoonResponse = {
  id: number
  name: string
  inserted_at: string
  updated_at: string
}

const MOON_VALIDATION_DELAY_MS = 380
const MOON_SEARCH_DELAY_MS = 150
const MOON_NAME_PATTERN = /^\w+$/
const SUPPORTED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif']
const MAX_IMAGE_FILE_SIZE_BYTES = 15 * 1024 * 1024

// Maximum allowed lengths for inputs (adjustable)
const TITLE_MAX_LENGTH = 100
const BODY_MAX_LENGTH = 5000

const route = useRoute()
const router = useRouter()
const errorBanner = useErrorBannerStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const postModeOptions = [
  { label: 'Text', value: 'text' },
  { label: 'Image', value: 'image' },
]

const postMode = ref<PostMode>('text')
// Moon pages link here with `?moon=<name>` to pre-fill the moon.
const moonInput = ref(typeof route.query.moon === 'string' ? route.query.moon : '')
const title = ref('')
const body = ref('')
const selectedFile = ref<File | null>(null)
const bodyTextArea = ref<HTMLTextAreaElement | null>(null)
const isDragActive = ref(false)
const isSubmitting = ref(false)
const moonStatus = ref<MoonStatus>('idle')
const selectedMoon = ref<MoonResponse | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)
const moonSuggestions = ref<MoonSuggestion[]>([])
const highlightedSuggestion = ref(-1)
const isMoonInputFocused = ref(false)

const errors = ref({
  moon: '',
  title: '',
  body: '',
  file: '',
})

const isMoonNameInSync = computed(() => {
  if (!selectedMoon.value) {
    return false
  }

  return selectedMoon.value.name.toLowerCase() === moonInput.value.trim().toLowerCase()
})

const isTitleCharacterCountAtLimit = computed(() => {
  return title.value.length >= TITLE_MAX_LENGTH
})

const isBodyCharacterCountAtLimit = computed(() => {
  return body.value.length >= BODY_MAX_LENGTH
})

let moonValidationTimeout: ReturnType<typeof setTimeout> | null = null
let moonValidationRequestId = 0

const clearMoonValidationTimer = () => {
  if (moonValidationTimeout) {
    clearTimeout(moonValidationTimeout)
    moonValidationTimeout = null
  }
}

const resetMoonSelection = () => {
  moonValidationRequestId += 1
  selectedMoon.value = null
  moonStatus.value = 'idle'
}

const getFileExtension = (filename: string) => {
  const index = filename.lastIndexOf('.')
  return index >= 0 ? filename.slice(index).toLowerCase() : ''
}

const isSupportedImageFile = (file: File) => {
  const hasSupportedType = file.type.startsWith('image/')
  const extension = getFileExtension(file.name)
  const hasSupportedExtension = SUPPORTED_IMAGE_EXTENSIONS.includes(extension)

  return hasSupportedType && hasSupportedExtension
}

const isWithinImageFileSizeLimit = (file: File) => {
  return file.size <= MAX_IMAGE_FILE_SIZE_BYTES
}

const setSelectedFile = (file: File | null) => {
  errors.value.file = ''

  if (!file) {
    selectedFile.value = null
    return
  }

  if (!isSupportedImageFile(file)) {
    selectedFile.value = null
    errors.value.file = 'Please upload a .jpg, .jpeg, .png, or .gif image'
    return
  }

  if (!isWithinImageFileSizeLimit(file)) {
    selectedFile.value = null
    errors.value.file = 'Please upload an image that is 15 MB or smaller'
    return
  }

  selectedFile.value = file
}

const validateMoonNow = async () => {
  clearMoonValidationTimer()

  if (!backendUrl) {
    moonStatus.value = 'error'
    return
  }

  const moonName = moonInput.value.trim()

  if (!moonName) {
    resetMoonSelection()
    return
  }

  moonStatus.value = 'checking'
  const currentRequestId = ++moonValidationRequestId
  const requestStartedAt = Date.now()

  try {
    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.get<MoonResponse>(`${base}/moon/${encodeURIComponent(moonName)}`)

    if (currentRequestId !== moonValidationRequestId) {
      return
    }

    await waitForMinimumVisibleTime(requestStartedAt)

    if (currentRequestId !== moonValidationRequestId) {
      return
    }

    selectedMoon.value = response.data
    moonStatus.value = 'exists'
  } catch (error) {
    if (currentRequestId !== moonValidationRequestId) {
      return
    }

    await waitForMinimumVisibleTime(requestStartedAt)

    if (currentRequestId !== moonValidationRequestId) {
      return
    }

    selectedMoon.value = null

    if (axios.isAxiosError(error) && error.response?.status === 404) {
      moonStatus.value = 'missing'
      return
    }

    moonStatus.value = 'error'
  }
}

const scheduleMoonValidation = () => {
  clearMoonValidationTimer()

  const moonName = moonInput.value.trim()
  if (!moonName) {
    resetMoonSelection()
    return
  }

  resetMoonSelection()
  moonStatus.value = 'checking'
  moonValidationTimeout = setTimeout(() => {
    void validateMoonNow()
  }, MOON_VALIDATION_DELAY_MS)
}

// Suggestions are a convenience on top of the exact-name check above,
// so search failures just leave the list empty.
let moonSearchTimeout: ReturnType<typeof setTimeout> | null = null
let moonSearchRequestId = 0
let skipNextMoonSearch = false

const showMoonSuggestions = computed(() => {
  if (!isMoonInputFocused.value || moonSuggestions.value.length === 0) {
    return false
  }

  // Nothing to suggest once the only match is what's already typed.
  const [onlySuggestion] = moonSuggestions.value
  return !(
    moonSuggestions.value.length === 1 &&
    onlySuggestion?.name.toLowerCase() === moonInput.value.trim().toLowerCase()
  )
})

const clearMoonSuggestions = () => {
  if (moonSearchTimeout) {
    clearTimeout(moonSearchTimeout)
    moonSearchTimeout = null
  }

  moonSearchRequestId += 1
  moonSuggestions.value = []
  highlightedSuggestion.value = -1
}

const searchMoons = async (term: string) => {
  if (!backendUrl) {
    return
  }

  const currentRequestId = ++moonSearchRequestId

  try {
    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.get<{ results: MoonSuggestion[] }>(
      `${base}/moon/search/${encodeURIComponent(term)}`,
    )

    if (currentRequestId === moonSearchRequestId) {
      moonSuggestions.value = response.data.results
      highlightedSuggestion.value = -1
    }
  } catch {
    if (currentRequestId === moonSearchRequestId) {
      moonSuggestions.value = []
    }
  }
}

const scheduleMoonSearch = () => {
  const term = moonInput.value.trim()
  clearMoonSuggestions()

  if (!term || !MOON_NAME_PATTERN.test(term)) {
    return
  }

  moonSearchTimeout = setTimeout(() => {
    void searchMoons(term)
  }, MOON_SEARCH_DELAY_MS)
}

const selectMoonSuggestion = (suggestion: MoonSuggestion) => {
  clearMoonSuggestions()
  skipNextMoonSearch = true
  moonInput.value = suggestion.name
}

const onMoonInputBlur = () => {
  isMoonInputFocused.value = false
  void validateMoonNow()
}

const onMoonInputKeydown = (event: KeyboardEvent) => {
  if (!showMoonSuggestions.value) {
    return
  }

  const count = moonSuggestions.value.length

  if (event.key === 'ArrowDown') {
    event.preventDefault()
    highlightedSuggestion.value = (highlightedSuggestion.value + 1) % count
  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    highlightedSuggestion.value =
      highlightedSuggestion.value <= 0 ? count - 1 : highlightedSuggestion.value - 1
  } else if (event.key === 'Enter') {
    const suggestion = moonSuggestions.value[highlightedSuggestion.value]
    if (suggestion) {
      event.preventDefault()
      selectMoonSuggestion(suggestion)
    }
  } else if (event.key === 'Escape') {
    event.preventDefault()
    clearMoonSuggestions()
  }
}

const onDragEnter = () => {
  isDragActive.value = true
}

const onDragOver = () => {
  isDragActive.value = true
}

const onDragLeave = () => {
  isDragActive.value = false
}

const onDrop = (event: DragEvent) => {
  isDragActive.value = false
  const file = event.dataTransfer?.files?.[0] ?? null
  setSelectedFile(file)
}

const onFileChange = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0] ?? null
  setSelectedFile(file)
}

const openFilePicker = () => {
  fileInput.value?.click()
}

const createEmptyErrors = () => ({
  moon: '',
  title: '',
  body: '',
  file: '',
})

const autoGrowBody = async () => {
  await nextTick()

  const textArea = bodyTextArea.value
  if (!textArea) {
    return
  }

  const computedStyle = window.getComputedStyle(textArea)
  const minHeight = Number.parseFloat(computedStyle.minHeight) || 0
  const borderTop = Number.parseFloat(computedStyle.borderTopWidth) || 0
  const borderBottom = Number.parseFloat(computedStyle.borderBottomWidth) || 0

  textArea.style.height = 'auto'
  const nextHeight = Math.max(textArea.scrollHeight + borderTop + borderBottom, minHeight)
  textArea.style.height = `${nextHeight}px`
}

const validateForm = async () => {
  const nextErrors = createEmptyErrors()

  let isValid = true

  if (!moonInput.value.trim()) {
    nextErrors.moon = 'Moon is required'
    isValid = false
  } else {
    if (!isMoonNameInSync.value || moonStatus.value !== 'exists') {
      await validateMoonNow()
    }

    if (!selectedMoon.value || !isMoonNameInSync.value || moonStatus.value !== 'exists') {
      nextErrors.moon = 'Please choose an existing moon'
      isValid = false
    }
  }

  if (!title.value.trim()) {
    nextErrors.title = 'Title is required'
    isValid = false
  } else if (title.value.length > TITLE_MAX_LENGTH) {
    nextErrors.title = `Title must be ${TITLE_MAX_LENGTH} characters or fewer`
    isValid = false
  }

  if (postMode.value === 'text') {
    if (!body.value.trim()) {
      nextErrors.body = 'Text is required'
      isValid = false
    } else if (body.value.length > BODY_MAX_LENGTH) {
      nextErrors.body = `Text must be ${BODY_MAX_LENGTH} characters or fewer`
      isValid = false
    }
  } else if (!selectedFile.value) {
    nextErrors.file = 'Image is required'
    isValid = false
  }

  return {
    isValid,
    errors: nextErrors,
  }
}

const submitPost = async () => {
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

    if (!validationResult.isValid || !selectedMoon.value) {
      await waitForMinimumVisibleTime(submitStartedAt)
      errors.value = validationResult.errors
      return
    }

    const base = backendUrl.replace(/\/$/, '')
    const payload = new FormData()
    payload.set('title', title.value.trim())
    payload.set('type', postMode.value)
    payload.set('moon_id', String(selectedMoon.value.id))

    if (postMode.value === 'text') {
      payload.set('body', body.value.trim())
    } else if (selectedFile.value) {
      payload.set('file', selectedFile.value)
    }

    const response = await axios.post(`${base}/post`, payload)
    const postId = response.data?.id

    await waitForMinimumVisibleTime(submitStartedAt)

    if (typeof postId === 'number') {
      await router.push({ name: 'post', params: { post_id: String(postId) } })
    } else {
      await router.push({ name: 'all', query: { sort: 'new' } })
    }
  } catch (error) {
    // Some failures (unsupported file, image storage problems) come back as
    // plain text rather than `{ errors }`; see enceladus/PARITY.md.
    const plainTextMessage =
      axios.isAxiosError(error) && typeof error.response?.data === 'string'
        ? error.response.data
        : ''

    if (axios.isAxiosError(error) && error.response?.status === 400) {
      const responseErrors = error.response.data?.errors
      const nextErrors = createEmptyErrors()

      if (!responseErrors && plainTextMessage && postMode.value === 'image') {
        nextErrors.file = plainTextMessage
      }

      if (responseErrors?.moon_id?.[0]) {
        nextErrors.moon = responseErrors.moon_id[0]
      }

      if (responseErrors?.title?.[0]) {
        nextErrors.title = responseErrors.title[0]
      }

      if (responseErrors?.body?.[0]) {
        if (postMode.value === 'text') {
          nextErrors.body = responseErrors.body[0]
        } else {
          nextErrors.file = responseErrors.body[0]
        }
      }

      if (responseErrors?.type?.[0]) {
        errorBanner.show(responseErrors.type[0])
        return
      }

      if (Object.values(nextErrors).some(Boolean)) {
        pendingErrors = nextErrors
      } else {
        errorBanner.show(plainTextMessage || "Post couldn't be created. Please try again.")
      }
      return
    }

    // The API answers 403 (not 401) when there's no session.
    if (axios.isAxiosError(error) && error.response?.status === 403) {
      errorBanner.show('Please log in to create a post.')
      return
    }

    // 502 / 503: the image upload or image storage failed.
    const status = axios.isAxiosError(error) ? error.response?.status : undefined
    if ((status === 502 || status === 503) && plainTextMessage && postMode.value === 'image') {
      pendingErrors = { ...createEmptyErrors(), file: plainTextMessage }
      return
    }

    errorBanner.show("Post couldn't be created. Please try again.")
  } finally {
    await waitForMinimumVisibleTime(submitStartedAt)

    if (pendingErrors) {
      errors.value = pendingErrors
    }

    isSubmitting.value = false
  }
}

watch(moonInput, () => {
  errors.value.moon = ''
  scheduleMoonValidation()

  if (skipNextMoonSearch) {
    skipNextMoonSearch = false
  } else {
    scheduleMoonSearch()
  }
})

watch(title, () => {
  errors.value.title = ''
})

watch(body, () => {
  errors.value.body = ''
  void autoGrowBody()
})

watch(postMode, (mode) => {
  errors.value.body = ''
  errors.value.file = ''

  if (mode === 'text') {
    selectedFile.value = null
  } else {
    body.value = ''
  }
})

if (moonInput.value) {
  void validateMoonNow()
}

onBeforeUnmount(() => {
  clearMoonValidationTimer()
  clearMoonSuggestions()
})
</script>

<style scoped>
.postSection {
  background: var(--bg-sub);
  border: 1px solid var(--bg-2);
  border-radius: 20px;
  padding: 2rem 1.5rem;
  width: 100%;
  margin-top: 2rem;
  position: relative;
}

main {
  width: 40rem;
}

h1 {
  margin-bottom: 1.5rem;
}

.moonInput {
  width: 100% !important;
  margin-top: 0;
  border-radius: 10px;
  flex-shrink: 0;
}

.moonCombobox {
  position: relative;
  flex: 1;
  min-width: 0;
}

.moonSuggestions {
  position: absolute;
  top: calc(100% + 0.25rem);
  left: 0;
  right: 0;
  z-index: 5;
  list-style: none;
  padding: 0.25rem;
  border: 1px solid var(--bg-2);
  border-radius: 10px;
  background: var(--bg-sub);
  box-shadow: 0 5px 20px rgb(0 0 0 / 10%);
}

.moonSuggestions li {
  padding: 0.45rem 0.6rem;
  border-radius: 7px;
  cursor: pointer;
}

.moonSuggestions li.highlighted {
  background: var(--bg-2);
}

.moonInputRow {
  width: calc(100% / 2);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.moonInputSpinner {
  width: 20px;
  height: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
}

.titleInput {
  margin-top: 2rem;
  border-bottom-left-radius: 0;
  border-bottom-right-radius: 0;
  border-top-left-radius: 10px;
  border-top-right-radius: 10px;
  border-bottom: 0px !important;
}
.textArea {
  border-top-left-radius: 0;
  border-top-right-radius: 0;
  border-bottom-left-radius: 10px;
  border-bottom-right-radius: 10px;
}

.textInput:focus,
.textArea:focus {
  position: relative;
  z-index: 1;
  outline: 2px solid var(--accent-color);
  outline-offset: 1px;
}
.textInput,
.textArea {
  width: 100%;
  border: 1px solid var(--bg-2);
  background: transparent;
  color: var(--text-1);
  font-size: 1rem;
  padding: 0.75rem 0.75rem;
  background-color: var(--bg-1);
}

.textArea {
  resize: none;
  min-height: calc(1.35em * 3 + 1.44rem);
  overflow-y: hidden;
  line-height: 1.35;
}

.textInput::placeholder,
.textArea::placeholder {
  color: var(--text-3);
}

.feedback {
  font-size: 1rem;
  margin-top: 0.5rem;
}
.feedback + .feedback {
  margin-top: 0.25rem;
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

.feedback.success {
  color: var(--vote-up);
}

.feedback.error {
  color: var(--text-error);
}

.dropzone {
  background-color: var(--bg-1);
  position: relative;
  border: 2px dashed var(--bg-3);
  padding: 2.5rem 1rem;
  text-align: center;
  transition:
    border-color 0.2s ease,
    background-color 0.2s ease;
}
.dropzone {
  border-top-left-radius: 0;
  border-top-right-radius: 0;
  border-bottom-left-radius: 10px;
  border-bottom-right-radius: 10px;
}

.dropzone.dragActive {
  border-color: var(--text-3);
}

.dropzone:hover .browseButton {
  text-decoration: underline;
}

.fileInput {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.dropzonePrimary {
  font-size: 1.2rem;
  font-weight: 600;
  margin-bottom: 0.2rem;
}

.dropzoneSecondary {
  font-family: 'Roboto Mono', monospace;
  color: var(--text-2);
  font-size: 0.8rem;
}

.browseButton {
  font-family: 'Roboto Mono', monospace;
  color: var(--text-2);
  border: none;
  background: transparent;
  font-size: 0.8rem;
  cursor: pointer;
  text-decoration: none;
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
