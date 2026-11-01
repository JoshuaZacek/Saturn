<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import CharacterCounter from '@/components/CharacterCounter.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import { COMMENT_MAX_LENGTH } from '@/utils/characterCount'

// One composer for comments and replies: a field that grows with its text,
// with the counter and buttons underneath. At rest (empty, unfocused) it's a
// single quiet line; the buttons open out when you start.
const props = withDefaults(
  defineProps<{
    modelValue: string
    label: string
    placeholder?: string
    submitLabel?: string
    loading?: boolean
    error?: string
    // Replies: always open, with Cancel, and focused when shown.
    reply?: boolean
  }>(),
  {
    placeholder: '',
    submitLabel: 'Post',
    error: '',
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
  submit: []
  cancel: []
}>()

const textarea = ref<HTMLTextAreaElement | null>(null)
// Focus anywhere in the composer (the field or its buttons) keeps it open.
const isFocused = ref(false)

const onFocusOut = (event: FocusEvent) => {
  const form = event.currentTarget as HTMLElement
  isFocused.value = form.contains(event.relatedTarget as Node | null)
}
const errorId = `composer-error-${Math.random().toString(36).slice(2)}`

const isOpen = computed(() => props.reply || isFocused.value || props.modelValue.length > 0)
const canSubmit = computed(() => props.modelValue.trim().length > 0)

const autoGrow = async () => {
  await nextTick()
  const field = textarea.value
  if (!field) {
    return
  }

  field.style.height = 'auto'
  field.style.height = `${field.scrollHeight}px`
}

const onInput = (event: Event) => {
  emit('update:modelValue', (event.target as HTMLTextAreaElement).value)
  void autoGrow()
}

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
    event.preventDefault()
    if (canSubmit.value && !props.loading) {
      emit('submit')
    }
  } else if (event.key === 'Escape' && props.reply) {
    event.preventDefault()
    emit('cancel')
  }
}

// Cleared after posting: shrink back.
watch(
  () => props.modelValue,
  (value) => {
    if (value === '') {
      void autoGrow()
    }
  },
)

// Replies (and edits, which start with the comment's text) open focused, with
// the caret after the text and the field tall enough to show all of it.
onMounted(() => {
  void autoGrow()

  const field = textarea.value
  if (props.reply && field) {
    field.focus()
    field.setSelectionRange(field.value.length, field.value.length)
  }
})
</script>

<template>
  <div class="composerWrap">
    <form
      class="composer"
      :class="{ open: isOpen, reply }"
      @submit.prevent="canSubmit && emit('submit')"
      @focusin="isFocused = true"
      @focusout="onFocusOut"
    >
      <textarea
        ref="textarea"
        class="composerField"
        :value="modelValue"
        :aria-label="label"
        :aria-invalid="!!error || undefined"
        :aria-describedby="error ? errorId : undefined"
        :placeholder="placeholder"
        rows="1"
        @input="onInput"
        @keydown="onKeydown"
      ></textarea>

      <div class="composerFooterWrap">
        <div class="composerFooter">
          <CharacterCounter :text="modelValue" :max="COMMENT_MAX_LENGTH" />
          <div class="composerButtons">
            <SubmitButton v-if="reply" variant="secondary" size="sm" @click="emit('cancel')">
              Cancel
            </SubmitButton>
            <SubmitButton type="submit" size="sm" :loading="loading" :disabled="!canSubmit">
              {{ submitLabel }}
            </SubmitButton>
          </div>
        </div>
      </div>
    </form>
    <p v-if="error" :id="errorId" class="composerError" role="alert">{{ error }}</p>
  </div>
</template>

<style scoped>
.composer {
  display: flex;
  flex-direction: column;
  border-radius: var(--radius-lg);
  background-color: var(--surface);
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--duration-fast) var(--ease-out);
}

/* The field and its buttons are one control, so focus rings the whole box. */
.composer:focus-within {
  box-shadow:
    0 0 0 1px var(--accent-color),
    var(--focus-ring);
}

.composerField {
  display: block;
  width: 100%;
  min-height: 2.75rem;
  max-height: 24rem;
  padding: 0.7rem 0.9rem;
  border: none;
  border-radius: inherit;
  background: transparent;
  font-size: var(--text-subhead);
  line-height: 1.45;
  resize: none;
  overflow-y: auto;
}

.composerField::placeholder {
  color: var(--text-3);
}

.composerField:focus,
.composerField:focus-visible {
  outline: none;
}

/* Opens out under the field as you start writing. Hidden (so its buttons
   can't be tabbed to) once it has closed. */
.composerFooterWrap {
  display: grid;
  grid-template-rows: 0fr;
  visibility: hidden;
  transition:
    grid-template-rows var(--duration-base) var(--ease-out),
    visibility 0s linear var(--duration-base);
}

.open .composerFooterWrap {
  grid-template-rows: 1fr;
  visibility: visible;
  transition: grid-template-rows var(--duration-base) var(--ease-out);
}

.composerFooter {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  min-height: 0;
  overflow: hidden;
  padding: 0 0.5rem 0 0.9rem;
  transition: padding var(--duration-base) var(--ease-out);
}

.open .composerFooter {
  padding-block: 0 0.5rem;
}

.composerButtons {
  display: flex;
  gap: 0.5rem;
  margin-left: auto;
}

.composerError {
  margin-top: 0.5rem;
  font-size: var(--text-footnote);
  color: var(--danger);
}

/* iOS zooms into text fields under 16px when they're focused. */
@media (pointer: coarse) {
  .composerField {
    font-size: var(--text-body);
  }
}
</style>
