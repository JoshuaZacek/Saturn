<template>
  <main class="formPage">
    <PageHeader title="Create post" />

    <form class="formCard" novalidate @submit.prevent="submitPost">
      <SegmentedControl
        class="postType"
        size="sm"
        label="Post type"
        :model-value="postMode"
        :options="postModeOptions"
        @update:model-value="postMode = $event as PostMode"
      />

      <div class="formField">
        <label class="fieldLabel" for="moon">Moon</label>
        <div class="moonCombobox">
          <div class="prefixField" :class="{ error: !!moonMessage }">
            <span class="prefix" aria-hidden="true">/</span>
            <input
              id="moon"
              v-model="moonInput"
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
              :aria-invalid="!!moonMessage || undefined"
              aria-describedby="moon-message"
              autocomplete="off"
              autocapitalize="off"
              spellcheck="false"
              placeholder="moon"
              @focus="isMoonInputFocused = true"
              @blur="onMoonInputBlur"
              @keydown="onMoonInputKeydown"
            />
            <InputStatusIndicator :status="moonIndicatorStatus" />
          </div>

          <Transition name="suggestions">
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
          </Transition>
        </div>
        <p id="moon-message" class="fieldMessage error">{{ moonMessage }}</p>
      </div>

      <div class="formField">
        <div class="labelRow">
          <label class="fieldLabel" for="title">Title</label>
          <CharacterCounter :text="title" :max="TITLE_MAX_LENGTH" :show-within="20" />
        </div>
        <input
          id="title"
          ref="titleInput"
          v-model="title"
          class="field"
          :class="{ error: !!errors.title }"
          type="text"
          name="title"
          autocomplete="off"
          :aria-invalid="!!errors.title || undefined"
          aria-describedby="title-message"
          @keydown="onTitleKeydown"
        />
        <p id="title-message" class="fieldMessage error">{{ errors.title }}</p>
      </div>

      <div v-if="postMode === 'text'" class="formField">
        <div class="labelRow">
          <label class="fieldLabel" for="body">Text</label>
          <CharacterCounter :text="body" :max="BODY_MAX_LENGTH" />
        </div>
        <textarea
          id="body"
          ref="bodyTextArea"
          v-model="body"
          class="field textArea"
          :class="{ error: !!errors.body }"
          name="body"
          rows="5"
          :aria-invalid="!!errors.body || undefined"
          aria-describedby="body-message"
          @input="autoGrowBody"
        />
        <p id="body-message" class="fieldMessage error">{{ errors.body }}</p>
      </div>

      <div v-else class="formField">
        <label class="fieldLabel" for="image">Image</label>
        <div
          class="imageField"
          :class="{ dragActive: isDragActive, hasFile: !!selectedFile, error: !!errors.file }"
          @dragenter.prevent="onDragEnter"
          @dragover.prevent="onDragOver"
          @dragleave.prevent="onDragLeave"
          @drop.prevent="onDrop"
        >
          <input
            id="image"
            ref="fileInput"
            class="fileInput"
            type="file"
            accept="image/png,image/jpeg,image/gif"
            aria-describedby="image-hint image-message"
            :tabindex="selectedFile ? -1 : undefined"
            @change="onFileChange"
          />

          <div v-if="!selectedFile" class="dropzone">
            <span class="dropzoneIcon" aria-hidden="true"><ImageIcon :size="24" /></span>
            <p class="dropzonePrimary">
              Drag an image here, or <span class="browse">choose one</span>
            </p>
            <p id="image-hint" class="dropzoneSecondary">JPG, PNG or GIF, up to 15 MB</p>
          </div>

          <div v-else class="imagePreview">
            <img
              v-if="previewUrl"
              class="previewImage"
              :src="previewUrl"
              alt="The image you chose"
            />
            <div class="previewBar">
              <div class="fileInfo">
                <span class="fileName">{{ selectedFile.name }}</span>
                <span class="fileSize">{{ formatFileSize(selectedFile.size) }}</span>
              </div>
              <button type="button" class="btn-ghost removeButton" @click="removeFile">
                Remove
              </button>
              <button type="button" class="btn-secondary" @click="openFilePicker">Replace</button>
            </div>
          </div>
        </div>
        <p id="image-message" class="fieldMessage error">{{ errors.file }}</p>
      </div>

      <div class="formFooter">
        <SubmitButton type="submit" size="lg" :loading="isSubmitting">Post</SubmitButton>
      </div>
    </form>
  </main>
</template>

<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import CharacterCounter from '@/components/CharacterCounter.vue'
import InputStatusIndicator from '@/components/InputStatusIndicator.vue'
import PageHeader from '@/components/PageHeader.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import ImageIcon from '@/components/icons/ImageIcon.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore } from '@/stores/ui'

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
const uiStore = useUIStore()
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
const previewUrl = ref<string | null>(null)
const titleInput = ref<HTMLInputElement | null>(null)
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

const moonIndicatorStatus = computed(() => {
  if (moonStatus.value === 'checking') {
    return 'checking'
  }

  return moonStatus.value === 'exists' ? 'valid' : null
})

const isMoonNameInSync = computed(() => {
  if (!selectedMoon.value) {
    return false
  }

  return selectedMoon.value.name.toLowerCase() === moonInput.value.trim().toLowerCase()
})

// While typing, someone may still be searching the suggestions for the right
// moon, so "doesn't exist" waits until they leave the field. Typing again
// hides it until they leave again.
const hasLeftMoonInput = ref(moonInput.value.length > 0)

const moonMessage = computed(() => {
  if (errors.value.moon) {
    return errors.value.moon
  }

  return moonStatus.value === 'missing' && hasLeftMoonInput.value ? 'This moon does not exist.' : ''
})

// The chosen image is shown before posting.
watch(selectedFile, (file) => {
  if (previewUrl.value) {
    URL.revokeObjectURL(previewUrl.value)
  }
  previewUrl.value = file ? URL.createObjectURL(file) : null
})

const formatFileSize = (bytes: number) =>
  bytes >= 1024 * 1024
    ? `${(bytes / (1024 * 1024)).toFixed(1)} MB`
    : `${Math.max(1, Math.round(bytes / 1024))} KB`

let moonValidationTimeout: ReturnType<typeof setTimeout> | null = null
let moonValidationRequestId = 0
// The name the latest check was for, and whether it's still waiting on the API.
let checkedMoonName: string | null = null
let isMoonCheckInFlight = false

const clearMoonValidationTimer = () => {
  if (moonValidationTimeout) {
    clearTimeout(moonValidationTimeout)
    moonValidationTimeout = null
  }
}

const resetMoonSelection = () => {
  moonValidationRequestId += 1
  checkedMoonName = null
  isMoonCheckInFlight = false
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

  // Don't re-check (and flash the spinner) for a name that's already been
  // checked or is being checked, e.g. when the input is blurred right after.
  if (
    checkedMoonName === moonName &&
    (isMoonCheckInFlight || moonStatus.value === 'exists' || moonStatus.value === 'missing')
  ) {
    return
  }

  checkedMoonName = moonName
  isMoonCheckInFlight = true
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
  } finally {
    if (currentRequestId === moonValidationRequestId) {
      isMoonCheckInFlight = false
    }
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
  hasLeftMoonInput.value = true
  void validateMoonNow()
}

// Enter moves on to the title rather than submitting half a form.
const onMoonInputKeydown = (event: KeyboardEvent) => {
  const isPickingSuggestion = showMoonSuggestions.value && highlightedSuggestion.value >= 0
  if (event.key === 'Enter' && !isPickingSuggestion) {
    event.preventDefault()
    clearMoonSuggestions()
    void validateMoonNow()
    titleInput.value?.focus()
    return
  }

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

const removeFile = () => {
  setSelectedFile(null)
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

// Enter in the title moves on to the text.
const onTitleKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Enter' && postMode.value === 'text') {
    event.preventDefault()
    bodyTextArea.value?.focus()
  }
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
    const status = axios.isAxiosError(error) ? error.response?.status : undefined
    const responseErrors = axios.isAxiosError(error) ? error.response?.data?.errors : undefined

    // The image couldn't be stored (502/503): the request failed, not the
    // form, so it's said in the error banner rather than under the field.
    if (status === 502 || status === 503) {
      errorBanner.show(
        responseErrors?.file?.[0]
          ? `${responseErrors.file[0]}. Please try again.`
          : "Your image couldn't be uploaded. Please try again.",
      )
      return
    }

    // Validation errors (400) come back as `{ errors: { field: [message] } }`
    // and are shown under their fields.
    if (responseErrors && status === 400) {
      if (responseErrors.type?.[0]) {
        errorBanner.show(responseErrors.type[0])
        return
      }

      const nextErrors = createEmptyErrors()
      const bodyError = responseErrors.body?.[0] ?? ''
      nextErrors.moon = responseErrors.moon_id?.[0] ?? ''
      nextErrors.title = responseErrors.title?.[0] ?? ''
      nextErrors.file = responseErrors.file?.[0] ?? ''

      if (postMode.value === 'text') {
        nextErrors.body = bodyError
      } else if (!nextErrors.file) {
        nextErrors.file = bodyError
      }

      if (Object.values(nextErrors).some(Boolean)) {
        pendingErrors = nextErrors
      } else {
        errorBanner.show("Post couldn't be created. Please try again.")
      }
      return
    }

    // The API answers 403 (not 401) when there's no session.
    if (status === 403) {
      errorBanner.show('Please log in to create a post.', {
        label: 'Log in',
        run: () => uiStore.openAuth('login'),
      })
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
  // A suggestion picked from the list is a finished choice, not more typing.
  hasLeftMoonInput.value = skipNextMoonSearch
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
  if (previewUrl.value) {
    URL.revokeObjectURL(previewUrl.value)
  }
})
</script>

<style scoped>
.formPage {
  width: 100%;
  max-width: var(--column-width);
}

.postType {
  align-self: flex-start;
}

.moonCombobox {
  position: relative;
}

.moonSuggestions {
  position: absolute;
  top: calc(100% + 0.35rem);
  left: 0;
  right: 0;
  z-index: 5;
  list-style: none;
  padding: 0.25rem;
  border-radius: var(--radius-md);
  background: var(--surface-raised);
  box-shadow: var(--shadow-lg);
  transform-origin: top center;
}

.moonSuggestions li {
  padding: 0.5rem 0.6rem;
  border-radius: var(--radius-xs);
  font-size: var(--text-subhead);
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.moonSuggestions li.highlighted {
  background: var(--fill-hover);
}

.suggestions-enter-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.suggestions-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-in-out),
    transform var(--duration-fast) var(--ease-in-out);
}

.suggestions-enter-from,
.suggestions-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.98);
}

.textArea {
  min-height: 9rem;
  line-height: 1.5;
  resize: none;
  overflow-y: hidden;
}

/* The picker: a dropzone, then the chosen image with what to do about it. */
.imageField {
  position: relative;
  border-radius: var(--radius-md);
}

.fileInput {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

/* With an image chosen, the input stays only for "Replace" to open. */
.hasFile .fileInput {
  inset: auto;
  width: 1px;
  height: 1px;
  pointer-events: none;
}

.dropzone {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.35rem;
  padding: 2rem 1rem;
  border: 1.5px dashed var(--separator-strong);
  border-radius: inherit;
  background-color: var(--bg-1);
  text-align: center;
  transition:
    border-color var(--duration-base) var(--ease-out),
    background-color var(--duration-base) var(--ease-out);
}

.imageField:has(.fileInput:focus-visible) .dropzone {
  outline: 2px solid var(--accent-color);
  outline-offset: 2px;
}

.dragActive .dropzone {
  border-color: var(--accent-color);
  background-color: color-mix(in srgb, var(--accent-color) 6%, var(--bg-1));
}

.error .dropzone {
  border-color: color-mix(in srgb, var(--danger) 60%, transparent);
}

.dropzoneIcon {
  display: inline-grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  margin-bottom: 0.35rem;
  border-radius: var(--radius-full);
  background-color: var(--fill-secondary);
  color: var(--text-2);
}

.dropzonePrimary {
  font-size: var(--text-subhead);
  font-weight: 500;
}

.browse {
  color: var(--accent-ink);
}

@media (hover: hover) {
  .imageField:not(.hasFile):hover .browse {
    text-decoration: underline;
  }
}

.dropzoneSecondary {
  font-size: var(--text-footnote);
  color: var(--text-2);
}

.imagePreview {
  overflow: hidden;
  border: 1px solid var(--separator);
  border-radius: inherit;
  background-color: var(--bg-1);
}

.previewImage {
  display: block;
  width: 100%;
  max-height: 20rem;
  object-fit: contain;
  background-color: color-mix(in srgb, var(--text-1) 4%, var(--surface));
}

.previewBar {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.6rem 0.6rem 0.6rem 0.85rem;
  border-top: 1px solid var(--separator);
}

.fileInfo {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.fileName {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--text-subhead);
  font-weight: 500;
}

.fileSize {
  font-size: var(--text-footnote);
  color: var(--text-2);
}

.removeButton {
  color: var(--danger);
  font-size: var(--text-subhead);
  padding: 0 0.6rem;
}

/* iOS zooms into text fields under 16px when they're focused. */
@media (pointer: coarse) {
  .moonSuggestions li {
    font-size: var(--text-body);
  }
}
</style>
