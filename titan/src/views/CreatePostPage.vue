<template>
  <main>
    <h1>Create post</h1>

    <SegmentedControl v-model="postMode" :options="postModeOptions" />

    <div class="postSection">
      <section class="moonSection">
        <div class="moonInputRow">
          <input
            id="moon"
            v-model="moonInput"
            class="textInput moonInput"
            type="text"
            name="moon"
            autocomplete="off"
            autocapitalize="off"
            spellcheck="false"
            placeholder="Moon..."
            @blur="validateMoonNow"
          />

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
              (.jpg, .jpeg, .png, .gif)
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
import { useRouter } from 'vue-router'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import CheckIcon from '@/components/icons/CheckIcon.vue'

type PostMode = 'text' | 'image'
type MoonStatus = 'idle' | 'checking' | 'exists' | 'missing' | 'error'
type MoonResponse = {
  id: number
  name: string
  inserted_at: string
  updated_at: string
}

const MOON_VALIDATION_DELAY_MS = 380
const MOON_CHECKING_MIN_VISIBLE_MS = 240
const SUBMIT_SPINNER_MIN_VISIBLE_MS = 250
const SUPPORTED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif']

const router = useRouter()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const postModeOptions = [
  { label: 'Text', value: 'text' },
  { label: 'Image', value: 'image' },
]

const postMode = ref<PostMode>('text')
const moonInput = ref('')
const title = ref('')
const body = ref('')
const selectedFile = ref<File | null>(null)
const bodyTextArea = ref<HTMLTextAreaElement | null>(null)
const isDragActive = ref(false)
const isSubmitting = ref(false)
const moonStatus = ref<MoonStatus>('idle')
const selectedMoon = ref<MoonResponse | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)

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

  const waitForMinimumCheckingVisibility = async () => {
    const elapsed = Date.now() - requestStartedAt
    const remaining = MOON_CHECKING_MIN_VISIBLE_MS - elapsed

    if (remaining > 0) {
      await new Promise<void>((resolve) => {
        setTimeout(resolve, remaining)
      })
    }
  }

  try {
    const base = backendUrl.replace(/\/$/, '')
    const response = await axios.get<MoonResponse>(`${base}/moon/${encodeURIComponent(moonName)}`)

    if (currentRequestId !== moonValidationRequestId) {
      return
    }

    await waitForMinimumCheckingVisibility()

    if (currentRequestId !== moonValidationRequestId) {
      return
    }

    selectedMoon.value = response.data
    moonStatus.value = 'exists'
  } catch (error) {
    if (currentRequestId !== moonValidationRequestId) {
      return
    }

    await waitForMinimumCheckingVisibility()

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

const waitForMinimumVisibleTime = async (startedAt: number, minimumVisibleMs: number) => {
  const elapsed = Date.now() - startedAt
  const remaining = minimumVisibleMs - elapsed

  if (remaining > 0) {
    await new Promise<void>((resolve) => {
      setTimeout(resolve, remaining)
    })
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
  }

  if (postMode.value === 'text') {
    if (!body.value.trim()) {
      nextErrors.body = 'Text is required'
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
      alert('Sorry, something went wrong.')
    }
    return
  }

  isSubmitting.value = true
  const submitStartedAt = Date.now()
  let pendingErrors: ReturnType<typeof createEmptyErrors> | null = null

  try {
    const validationResult = await validateForm()

    if (!validationResult.isValid || !selectedMoon.value) {
      await waitForMinimumVisibleTime(submitStartedAt, SUBMIT_SPINNER_MIN_VISIBLE_MS)
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

    await waitForMinimumVisibleTime(submitStartedAt, SUBMIT_SPINNER_MIN_VISIBLE_MS)

    if (typeof postId === 'number') {
      await router.push({ name: 'post', params: { post_id: String(postId) } })
    } else {
      await router.push({ name: 'all', query: { sort: 'new' } })
    }
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 400) {
      const responseErrors = error.response.data?.errors
      const nextErrors = createEmptyErrors()

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
        alert(responseErrors.type[0])
        return
      }

      pendingErrors = nextErrors
      return
    }

    if (axios.isAxiosError(error) && error.response?.status === 401) {
      alert('Please log in to create a post')
      return
    }

    alert("Post couldn't be created. Please try again.")
  } finally {
    await waitForMinimumVisibleTime(submitStartedAt, SUBMIT_SPINNER_MIN_VISIBLE_MS)

    if (pendingErrors) {
      errors.value = pendingErrors
    }

    isSubmitting.value = false
  }
}

watch(moonInput, () => {
  errors.value.moon = ''
  scheduleMoonValidation()
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

onBeforeUnmount(() => {
  clearMoonValidationTimer()
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
