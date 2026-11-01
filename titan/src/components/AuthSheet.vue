<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, ref } from 'vue'
import { useRouter } from 'vue-router'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SheetDialog from '@/components/SheetDialog.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore, type AuthMode } from '@/stores/ui'

// Log in and sign up, in a sheet over the page: centred on wide screens, from
// the bottom on phones. Opened from anywhere through the UI store.
const LOCAL_VALIDATION_DELAY_MS = 450

const modeOptions: Array<{ label: string; value: AuthMode }> = [
  { label: 'Log in', value: 'login' },
  { label: 'Sign up', value: 'signup' },
]

const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const form = ref<HTMLFormElement | null>(null)
const isSubmitting = ref(false)
const errors = ref({ username: '', email: '', password: '' })

const mode = computed(() => uiStore.authSheet.mode)
const isSignup = computed(() => mode.value === 'signup')

const clearErrors = () => {
  errors.value = { username: '', email: '', password: '' }
}

const focusFirstField = () => {
  const selector = isSignup.value ? 'input[name="username"]' : 'input[name="email"]'
  form.value?.querySelector<HTMLInputElement>(selector)?.focus()
}

// Starts over for next time, once it has finished closing.
const onClosed = () => {
  form.value?.reset()
  clearErrors()
  isSubmitting.value = false
  authStore.clearSessionExpired()
}

const switchMode = async (value: string) => {
  if (value !== 'login' && value !== 'signup') {
    return
  }

  clearErrors()
  uiStore.authSheet.mode = value
  await nextTick()
  focusFirstField()
}

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

const handleSubmit = async () => {
  if (isSubmitting.value) {
    return
  }

  isSubmitting.value = true
  await wait(LOCAL_VALIDATION_DELAY_MS)

  const currentForm = form.value
  if (!currentForm) {
    isSubmitting.value = false
    return
  }

  const field = (name: string) => currentForm.elements.namedItem(name) as HTMLInputElement | null
  const email = field('email')?.value.trim() ?? ''
  const username = field('username')?.value ?? ''
  const password = field('password')?.value ?? ''

  clearErrors()
  let isValid = true

  if (!email) {
    errors.value.email = 'Email is required'
    isValid = false
  } else if (!/.+@(?=[^@]+$).+\.(?=[^.]+$)/.test(email)) {
    errors.value.email = 'Please enter a valid email address'
    isValid = false
  }

  if (!password) {
    errors.value.password = 'Password is required'
    isValid = false
  } else if (password.length < 8 && isSignup.value) {
    errors.value.password = 'Your password must contain 8 characters or more'
    isValid = false
  }

  if (isSignup.value && !username.trim()) {
    errors.value.username = 'Username is required'
    isValid = false
  } else if (isSignup.value && username && !/^\w+$/.test(username)) {
    errors.value.username = 'Usernames can only contain letters, numbers and underscores'
    isValid = false
  }

  if (!isValid) {
    isSubmitting.value = false
    await nextTick()
    currentForm.querySelector<HTMLInputElement>('[aria-invalid="true"]')?.focus()
    return
  }

  // Disabled fields (the hidden username, when logging in) aren't sent.
  const formData = new FormData(currentForm)
  const endpoint = isSignup.value ? '/user/create' : '/user/login'

  try {
    const response = await axios.post(`${backendUrl}${endpoint}`, formData)
    authStore.login(response.data)
    router.go(0)
  } catch (err) {
    if (axios.isAxiosError(err) && err.response?.status == 400) {
      errors.value.email = err.response.data.errors?.email?.[0] ?? ''
      errors.value.username = err.response.data.errors?.username?.[0] ?? ''
      errors.value.password = err.response.data.errors?.password?.[0] ?? ''
    } else {
      errorBanner.show(
        isSignup.value
          ? "Couldn't sign up. Please try again."
          : "Couldn't log in. Please try again.",
      )
    }
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <SheetDialog
    class="authSheet"
    :open="uiStore.authSheet.open"
    :label="isSignup ? 'Sign up' : 'Log in'"
    :busy="isSubmitting"
    @close="uiStore.closeAuth()"
    @opened="focusFirstField"
    @closed="onClosed"
  >
    <template #header>
      <img class="logo" src="/logo.png" width="40" height="40" alt="" />
    </template>

    <SegmentedControl
      label="Log in or sign up"
      :model-value="mode"
      :options="modeOptions"
      @update:model-value="switchMode"
    />

    <p v-if="authStore.sessionExpired" class="sessionNotice" role="status">
      Your session has expired. Log in again to continue.
    </p>

    <form ref="form" class="authForm" novalidate @submit.prevent="handleSubmit">
      <!-- Only for signing up; opens and closes in place. -->
      <div class="collapsible" :class="{ open: isSignup }">
        <div class="collapsibleInner">
          <label class="formField">
            <span class="fieldLabel">Username</span>
            <input
              class="field"
              :class="{ error: !!errors.username }"
              name="username"
              type="text"
              autocomplete="nickname"
              autocapitalize="off"
              spellcheck="false"
              :disabled="!isSignup"
              :aria-invalid="!!errors.username || undefined"
              aria-describedby="auth-username-error"
              @input="errors.username = ''"
            />
            <span v-if="errors.username" id="auth-username-error" class="fieldError">{{
              errors.username
            }}</span>
          </label>
        </div>
      </div>

      <!-- People log in with their email, so password managers (Apple's
           Keychain especially) need it marked as the account's username. -->
      <label class="formField">
        <span class="fieldLabel">Email</span>
        <input
          class="field"
          :class="{ error: !!errors.email }"
          name="email"
          type="email"
          autocomplete="username"
          :aria-invalid="!!errors.email || undefined"
          aria-describedby="auth-email-error"
          @input="errors.email = ''"
        />
        <span v-if="errors.email" id="auth-email-error" class="fieldError">{{ errors.email }}</span>
      </label>

      <label class="formField">
        <span class="fieldLabel">Password</span>
        <input
          class="field"
          :class="{ error: !!errors.password }"
          name="password"
          type="password"
          :autocomplete="isSignup ? 'new-password' : 'current-password'"
          :aria-invalid="!!errors.password || undefined"
          aria-describedby="auth-password-error"
          @input="errors.password = ''"
        />
        <span v-if="errors.password" id="auth-password-error" class="fieldError">{{
          errors.password
        }}</span>
      </label>

      <SubmitButton class="submit" type="submit" size="lg" block :loading="isSubmitting">
        {{ isSignup ? 'Sign up' : 'Log in' }}
      </SubmitButton>
    </form>
  </SheetDialog>
</template>

<style scoped>
.logo {
  filter: var(--logo-filter);
  user-select: none;
  -webkit-user-drag: none;
}

.sessionNotice {
  padding: 0.6rem 0.75rem;
  border-radius: var(--radius-md);
  background-color: var(--fill-secondary);
  font-size: var(--text-footnote);
  color: var(--text-1);
}

.authForm {
  display: flex;
  flex-direction: column;
}

.formField {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

/* The same space between fields whether or not the username is showing. */
.authForm > .formField,
.collapsible.open {
  margin-bottom: 1rem;
}

.fieldLabel {
  font-size: var(--text-footnote);
  font-weight: 600;
  color: var(--text-2);
}

.fieldError {
  font-size: var(--text-footnote);
  line-height: 1.35;
  color: var(--danger);
}

.collapsible {
  display: grid;
  grid-template-rows: 0fr;
  visibility: hidden;
  transition:
    grid-template-rows var(--duration-base) var(--ease-out),
    margin-bottom var(--duration-base) var(--ease-out),
    visibility 0s linear var(--duration-base);
}

.collapsible.open {
  grid-template-rows: 1fr;
  visibility: visible;
  transition:
    grid-template-rows var(--duration-base) var(--ease-out),
    margin-bottom var(--duration-base) var(--ease-out);
}

.collapsibleInner {
  min-height: 0;
  overflow: hidden;
  /* Room for the field's focus ring inside the clipped area. */
  padding: 3px;
  margin: -3px;
}

.submit {
  margin-top: 0.25rem;
}
</style>
