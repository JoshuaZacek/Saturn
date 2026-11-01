<script setup lang="ts">
import axios from 'axios'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SheetDialog from '@/components/SheetDialog.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import ImageIcon from '@/components/icons/ImageIcon.vue'
import ErrorBanner from '@/components/ErrorBanner.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { AVATAR_COLORS, avatarInitial, type AvatarFields } from '@/utils/avatar'

// Changes a person's or moon's picture: an image they upload, or their
// monogram in one of our colours. Shows the result as it will look, in the
// shape it will have (people are circles, moons tiles).
type Mode = 'image' | 'monogram'

const MAX_IMAGE_BYTES = 5 * 1024 * 1024
const SUPPORTED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif']

const props = defineProps<{
  open: boolean
  kind: 'user' | 'moon'
  name: string
  avatar: AvatarFields
  // Where the change is sent, e.g. `/user/avatar`.
  endpoint: string
}>()

const emit = defineEmits<{
  close: []
  saved: [avatar: AvatarFields]
}>()

const modeOptions: Array<{ label: string; value: Mode }> = [
  { label: 'Image', value: 'image' },
  { label: 'Monogram', value: 'monogram' },
]

const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const title = computed(() => (props.kind === 'user' ? 'Profile picture' : 'Moon picture'))
const shape = computed(() => (props.kind === 'user' ? 'circle' : 'tile'))
const initial = computed(() => avatarInitial(props.name))

const mode = ref<Mode>('monogram')
const color = ref('')
const file = ref<File | null>(null)
const fileUrl = ref<string | null>(null)
const error = ref('')
const isSaving = ref(false)
const isDragActive = ref(false)
const fileInput = ref<HTMLInputElement | null>(null)

// Starts from what they have now, each time it opens.
const reset = () => {
  mode.value = props.avatar.avatar_image ? 'image' : 'monogram'
  color.value = props.avatar.avatar_color
  file.value = null
  error.value = ''
  isSaving.value = false
}

watch(
  () => props.open,
  (open) => open && reset(),
  { immediate: true },
)

watch(file, (next) => {
  if (fileUrl.value) {
    URL.revokeObjectURL(fileUrl.value)
  }
  fileUrl.value = next ? URL.createObjectURL(next) : null
})

onBeforeUnmount(() => {
  if (fileUrl.value) {
    URL.revokeObjectURL(fileUrl.value)
  }
})

const hasImage = computed(() => !!file.value || !!props.avatar.avatar_image)

const canSave = computed(() => {
  if (mode.value === 'image') {
    return !!file.value
  }

  return color.value !== props.avatar.avatar_color || !!props.avatar.avatar_image
})

const chooseFile = (next: File | null | undefined) => {
  error.value = ''

  if (!next) {
    return
  }

  const extension = next.name.slice(next.name.lastIndexOf('.')).toLowerCase()
  if (!next.type.startsWith('image/') || !SUPPORTED_EXTENSIONS.includes(extension)) {
    error.value = 'Please choose a JPG, PNG or GIF image'
    return
  }

  if (next.size > MAX_IMAGE_BYTES) {
    error.value = 'Please choose an image that is 5 MB or smaller'
    return
  }

  file.value = next
}

const onFileChange = (event: Event) => {
  const input = event.target as HTMLInputElement
  chooseFile(input.files?.[0])
  // Choosing the same file again still counts as a choice.
  input.value = ''
}

const onDrop = (event: DragEvent) => {
  isDragActive.value = false
  if (mode.value === 'image') {
    chooseFile(event.dataTransfer?.files?.[0])
  }
}

const onModeChange = (value: string) => {
  mode.value = value as Mode
  error.value = ''
}

// Colours are a radio group: one tab stop, arrow keys move the choice.
const onSwatchKeydown = (event: KeyboardEvent) => {
  const steps: Record<string, number> = {
    ArrowRight: 1,
    ArrowDown: 6,
    ArrowLeft: -1,
    ArrowUp: -6,
  }
  const step = steps[event.key]
  if (step === undefined) {
    return
  }

  event.preventDefault()
  const index = AVATAR_COLORS.findIndex((option) => option.name === color.value)
  const next = (index + step + AVATAR_COLORS.length) % AVATAR_COLORS.length
  color.value = AVATAR_COLORS[next]!.name
  const group = event.currentTarget as HTMLElement
  group.querySelectorAll<HTMLButtonElement>('.swatch')[next]?.focus()
}

const save = async () => {
  if (!backendUrl || !canSave.value || isSaving.value) {
    return
  }

  isSaving.value = true
  error.value = ''
  const startedAt = Date.now()

  try {
    const url = `${backendUrl.replace(/\/$/, '')}${props.endpoint}`
    let response

    if (mode.value === 'image' && file.value) {
      const payload = new FormData()
      payload.set('type', 'image')
      payload.set('file', file.value)
      response = await axios.post<AvatarFields>(url, payload)
    } else {
      response = await axios.post<AvatarFields>(url, { type: 'monogram', color: color.value })
    }

    await waitForMinimumVisibleTime(startedAt)
    isSaving.value = false
    emit('saved', response.data)
  } catch (err) {
    await waitForMinimumVisibleTime(startedAt)
    isSaving.value = false
    const data = axios.isAxiosError(err) ? err.response?.data : undefined
    error.value =
      data?.errors?.file?.[0] ??
      data?.errors?.color?.[0] ??
      "Your picture couldn't be saved. Please try again."
  }
}
</script>

<template>
  <SheetDialog
    class="avatarEditor"
    :open="open"
    :label="title"
    :busy="isSaving"
    @close="emit('close')"
  >
    <template #header>
      <h2 class="sheetTitle">{{ title }}</h2>
    </template>

    <SegmentedControl
      :label="`${title}: image or monogram`"
      :model-value="mode"
      :options="modeOptions"
      @update:model-value="onModeChange"
    />

    <!-- The picture as it will look. Drop an image on it, or choose one below. -->
    <div
      class="preview"
      :class="[shape, { dragActive: isDragActive && mode === 'image' }]"
      @dragenter.prevent="isDragActive = true"
      @dragover.prevent="isDragActive = true"
      @dragleave.prevent="isDragActive = false"
      @drop.prevent="onDrop"
    >
      <Transition name="preview-swap" mode="out-in">
        <img
          v-if="mode === 'image' && fileUrl"
          :key="fileUrl"
          class="previewImage"
          :class="shape"
          :src="fileUrl"
          alt="The image you chose"
        />
        <UserAvatar
          v-else-if="mode === 'image' && avatar.avatar_image"
          key="current-image"
          :name="name"
          :color="avatar.avatar_color"
          :image="avatar.avatar_image"
          :shape="shape"
          :size="112"
          exact
        />
        <span v-else-if="mode === 'image'" key="empty" class="emptyImage" :class="shape">
          <ImageIcon :size="32" />
        </span>
        <UserAvatar
          v-else
          key="monogram"
          :name="name"
          :color="color"
          :image="null"
          :shape="shape"
          :size="112"
          exact
        />
      </Transition>
    </div>

    <!-- Both choices take the same fixed room, so switching doesn't resize the
         sheet; they crossfade, like the preview above. -->
    <div class="choices">
      <Transition name="choice-swap" mode="out-in">
        <div v-if="mode === 'image'" key="image" class="imageChoice">
          <input
            ref="fileInput"
            class="visually-hidden"
            type="file"
            accept="image/png,image/jpeg,image/gif"
            tabindex="-1"
            aria-hidden="true"
            @change="onFileChange"
          />
          <button class="btn-secondary chooseButton" type="button" @click="fileInput?.click()">
            {{ hasImage ? 'Choose another image' : 'Choose an image' }}
          </button>
          <p class="hint">JPG, PNG or GIF, up to 5 MB</p>
        </div>

        <div
          v-else
          key="monogram"
          class="swatches"
          role="radiogroup"
          aria-label="Colour"
          @keydown="onSwatchKeydown"
        >
          <button
            v-for="option in AVATAR_COLORS"
            :key="option.name"
            class="swatch"
            :class="{ selected: option.name === color }"
            :style="{ '--avatar-hue': String(option.hue) }"
            type="button"
            role="radio"
            :aria-checked="option.name === color"
            :aria-label="option.label"
            :title="option.label"
            :tabindex="option.name === color ? 0 : -1"
            @click="color = option.name"
          >
            {{ initial }}
          </button>
        </div>
      </Transition>
    </div>

    <!-- Inside the sheet: the page's own error banner sits behind it. -->
    <Transition name="error-banner">
      <ErrorBanner v-if="error" class="editorError" :message="error" @dismiss="error = ''" />
    </Transition>

    <div class="sheetFooter">
      <button class="btn-secondary cancelButton" type="button" @click="emit('close')">
        Cancel
      </button>
      <SubmitButton :disabled="!canSave" :loading="isSaving" @click="save">Save</SubmitButton>
    </div>
  </SheetDialog>
</template>

<style scoped>
.sheetTitle {
  font-size: var(--text-title-3);
  font-weight: 600;
}

.preview {
  display: grid;
  place-items: center;
  align-self: center;
  width: 7rem;
  height: 7rem;
  margin: 0.5rem 0 0.25rem;
  border-radius: var(--radius-full);
  transition: box-shadow var(--duration-fast) var(--ease-out);
}

.preview.tile {
  border-radius: calc(112px * 0.28);
}

.preview.dragActive {
  box-shadow:
    0 0 0 3px var(--surface-raised),
    0 0 0 5px var(--accent-color);
}

.previewImage,
.emptyImage {
  width: 112px;
  height: 112px;
  border-radius: var(--radius-full);
}

.previewImage.tile,
.emptyImage.tile {
  border-radius: calc(112px * 0.28);
}

.previewImage {
  object-fit: cover;
  background-color: var(--fill-secondary);
}

/* No image yet: an outline of where it will go. */
.emptyImage {
  display: grid;
  place-items: center;
  border: 1.5px dashed var(--separator-strong);
  color: var(--text-3);
}

.preview-swap-enter-active,
.preview-swap-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.preview-swap-enter-from,
.preview-swap-leave-to {
  opacity: 0;
  transform: scale(0.96);
}

/* A fixed height, the taller of the two (two rows of colours), so neither
   choice changes the sheet's height. */
.choices {
  display: grid;
  place-items: center;
  height: 5.75rem;
}

.choice-swap-enter-active,
.choice-swap-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.choice-swap-enter-from {
  opacity: 0;
  transform: translateY(4px);
}

.choice-swap-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

.imageChoice {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.chooseButton {
  min-height: var(--control-md);
  padding: 0 1rem;
}

.hint {
  font-size: var(--text-footnote);
  color: var(--text-2);
}

/* Each colour is a little monogram in it, so it's clear what you'll get. */
.swatches {
  display: grid;
  grid-template-columns: repeat(6, 2.5rem);
  gap: 0.6rem;
}

.swatch {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background-color: hsl(var(--avatar-hue) var(--avatar-sat) var(--avatar-bg-l));
  color: hsl(var(--avatar-hue) var(--avatar-sat) var(--avatar-fg-l));
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition:
    box-shadow var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.swatch:active {
  transform: scale(0.94);
}

/* The chosen colour gets a ring, set off from it by the sheet's colour. */
.swatch.selected {
  box-shadow:
    0 0 0 2px var(--surface-raised),
    0 0 0 4px hsl(var(--avatar-hue) var(--avatar-sat) var(--avatar-fg-l));
}

.swatch:focus-visible {
  outline-offset: 4px;
}

.editorError {
  font-size: var(--text-subhead);
}

.sheetFooter {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

/* The same size as the button beside it. */
.cancelButton {
  min-height: var(--control-md);
  padding: 0 0.95rem;
  font-size: var(--text-body);
}

@media (max-width: 380px) {
  .swatches {
    grid-template-columns: repeat(6, 2.25rem);
    gap: 0.45rem;
  }

  .swatch {
    width: 2.25rem;
    height: 2.25rem;
  }
}
</style>
