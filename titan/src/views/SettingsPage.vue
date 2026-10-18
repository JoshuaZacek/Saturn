<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, ref, useTemplateRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AuthInput from '@/components/AuthInput.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import ArrowLeftIcon from '@/components/icons/ArrowLeftIcon.vue'
import CheckIcon from '@/components/icons/CheckIcon.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'

type Step = 'email' | 'password' | 'delete'

const EMAIL_PATTERN = /.+@(?=[^@]+$).+\.(?=[^.]+$)/
const PASSWORD_MIN_LENGTH = 8

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const stepSection = useTemplateRef<HTMLElement>('stepSection')

const step = computed<Step | null>(() => {
  const value = route.params.step
  return value === 'email' || value === 'password' || value === 'delete' ? value : null
})

// Shown on the main settings page after a step succeeds.
const notice = ref('')
const isSubmitting = ref(false)
const emailErrors = ref({ newEmail: '', confirmEmail: '' })
const passwordErrors = ref({ oldPassword: '', newPassword: '' })

const hasEmailErrors = computed(() => Object.values(emailErrors.value).some(Boolean))
const hasPasswordErrors = computed(() => Object.values(passwordErrors.value).some(Boolean))

const apiBase = () => {
  if (!backendUrl) {
    throw new Error('VITE_BACKEND_URL is not set')
  }

  return backendUrl.replace(/\/$/, '')
}

const returnToSettings = (message: string) => {
  notice.value = message
  void router.push('/settings')
}

watch(step, async (nextStep) => {
  emailErrors.value = { newEmail: '', confirmEmail: '' }
  passwordErrors.value = { oldPassword: '', newPassword: '' }
  isSubmitting.value = false

  if (!nextStep) {
    return
  }

  notice.value = ''
  await nextTick()
  stepSection.value?.querySelector<HTMLElement>('input, button')?.focus()
})

const submitEmail = async (event: Event) => {
  if (isSubmitting.value) {
    return
  }

  const formData = new FormData(event.target as HTMLFormElement)
  const newEmail = String(formData.get('newemail') ?? '').trim()
  const confirmEmail = String(formData.get('confirmemail') ?? '').trim()
  const nextErrors = { newEmail: '', confirmEmail: '' }

  if (!newEmail) {
    nextErrors.newEmail = 'New email is required'
  } else if (!EMAIL_PATTERN.test(newEmail)) {
    nextErrors.newEmail = 'Please enter a valid email address'
  } else if (newEmail === authStore.user.email) {
    nextErrors.newEmail = 'Your new email must be different from your current one'
  }

  if (!confirmEmail) {
    nextErrors.confirmEmail = 'Please confirm your new email'
  } else if (newEmail && confirmEmail !== newEmail) {
    nextErrors.confirmEmail = "Emails don't match"
  }

  emailErrors.value = nextErrors
  if (hasEmailErrors.value) {
    return
  }

  isSubmitting.value = true
  const submitStartedAt = Date.now()

  try {
    const payload = new FormData()
    payload.set('newemail', newEmail)
    await axios.post(`${apiBase()}/user/email`, payload)

    await waitForMinimumVisibleTime(submitStartedAt)
    authStore.changeEmail(newEmail)
    returnToSettings('Your email has been changed.')
  } catch (err) {
    await waitForMinimumVisibleTime(submitStartedAt)

    if (axios.isAxiosError(err) && err.response?.status === 400) {
      emailErrors.value.newEmail =
        err.response.data?.errors?.email?.[0] ?? "Your email couldn't be changed"
    } else {
      errorBanner.show("Your email couldn't be changed. Please try again.")
    }
  } finally {
    isSubmitting.value = false
  }
}

const submitPassword = async (event: Event) => {
  if (isSubmitting.value) {
    return
  }

  const formData = new FormData(event.target as HTMLFormElement)
  const oldPassword = String(formData.get('oldpassword') ?? '')
  const newPassword = String(formData.get('newpassword') ?? '')
  const nextErrors = { oldPassword: '', newPassword: '' }

  if (!oldPassword) {
    nextErrors.oldPassword = 'Current password is required'
  }

  if (!newPassword) {
    nextErrors.newPassword = 'New password is required'
  } else if (newPassword.length < PASSWORD_MIN_LENGTH) {
    nextErrors.newPassword = `Your new password must contain ${PASSWORD_MIN_LENGTH} characters or more`
  } else if (newPassword === oldPassword) {
    nextErrors.newPassword = 'Your new password must be different from your current one'
  }

  passwordErrors.value = nextErrors
  if (hasPasswordErrors.value) {
    return
  }

  isSubmitting.value = true
  const submitStartedAt = Date.now()

  try {
    const payload = new FormData()
    payload.set('oldpassword', oldPassword)
    payload.set('newpassword', newPassword)
    await axios.post(`${apiBase()}/user/password`, payload)

    await waitForMinimumVisibleTime(submitStartedAt)
    returnToSettings('Your password has been changed.')
  } catch (err) {
    await waitForMinimumVisibleTime(submitStartedAt)

    if (axios.isAxiosError(err) && err.response?.status === 400) {
      // The API reports every password problem under `password`; only
      // "Incorrect password" is about the current one.
      const message: string =
        err.response.data?.errors?.password?.[0] ?? "Your password couldn't be changed"

      if (message.toLowerCase().includes('incorrect')) {
        passwordErrors.value.oldPassword = message
      } else {
        passwordErrors.value.newPassword = message
      }
    } else {
      errorBanner.show("Your password couldn't be changed. Please try again.")
    }
  } finally {
    isSubmitting.value = false
  }
}

const deleteAccount = async () => {
  if (isSubmitting.value) {
    return
  }

  isSubmitting.value = true
  const submitStartedAt = Date.now()

  try {
    await axios.delete(`${apiBase()}/user`)
    await waitForMinimumVisibleTime(submitStartedAt)

    authStore.logout()
    await router.replace({ name: 'all', query: { sort: 'top', t: 'day' } })
    // Reload like log out does, so no page keeps state from the deleted account.
    router.go(0)
  } catch {
    await waitForMinimumVisibleTime(submitStartedAt)
    errorBanner.show("Your account couldn't be deleted. Please try again.")
    isSubmitting.value = false
  }
}
</script>

<template>
  <main>
    <template v-if="!step">
      <h1>Settings</h1>

      <p v-if="notice" class="notice" role="status">
        <CheckIcon :size="20" color="var(--vote-up)" />
        <span>{{ notice }}</span>
      </p>

      <div class="settingsList">
        <RouterLink class="settingRow" :to="{ name: 'settings', params: { step: 'email' } }">
          <span class="rowText">
            <span class="rowTitle">Email</span>
            <span class="rowDescription">{{ authStore.user.email }}</span>
          </span>
          <span class="rowAction">Change</span>
        </RouterLink>

        <RouterLink class="settingRow" :to="{ name: 'settings', params: { step: 'password' } }">
          <span class="rowText">
            <span class="rowTitle">Password</span>
          </span>
          <span class="rowAction">Change</span>
        </RouterLink>

        <RouterLink
          class="settingRow danger"
          :to="{ name: 'settings', params: { step: 'delete' } }"
        >
          <span class="rowText">
            <span class="rowTitle">Delete account</span>
            <span class="rowDescription">
              Your posts, comments, moons and votes will be deleted
            </span>
          </span>
          <span class="rowAction">Delete</span>
        </RouterLink>
      </div>
    </template>

    <section v-else ref="stepSection" class="settingsStep">
      <RouterLink class="backButton" to="/settings">
        <ArrowLeftIcon :size="18" />
        <span>Settings</span>
      </RouterLink>

      <template v-if="step === 'email'">
        <h1>Change email</h1>
        <p class="description">
          Your current email is <strong>{{ authStore.user.email }}</strong>
        </p>

        <form novalidate @submit.prevent="submitEmail">
          <div class="inputContainer">
            <AuthInput
              type="email"
              name="newemail"
              placeholder="New email..."
              aria-label="New email"
              autocomplete="email"
              :has-error="!!emailErrors.newEmail"
              @input="emailErrors.newEmail = ''"
            />
            <AuthInput
              type="email"
              name="confirmemail"
              placeholder="Confirm new email..."
              aria-label="Confirm new email"
              autocomplete="email"
              :has-error="!!emailErrors.confirmEmail"
              @input="emailErrors.confirmEmail = ''"
            />
          </div>

          <div v-if="hasEmailErrors" class="errorText">
            <p v-if="emailErrors.newEmail">{{ emailErrors.newEmail }}</p>
            <p v-if="emailErrors.confirmEmail">{{ emailErrors.confirmEmail }}</p>
          </div>

          <div class="buttonRow">
            <SubmitButton type="submit" :disabled="isSubmitting">Change email</SubmitButton>
            <span class="spinnerSlot" aria-hidden="true">
              <SpinnerLoader v-if="isSubmitting" :size="20" fgColor="var(--text-2)" />
            </span>
          </div>
        </form>
      </template>

      <template v-else-if="step === 'password'">
        <h1>Change password</h1>
        <p class="description">
          Your new password must contain {{ PASSWORD_MIN_LENGTH }} characters or more.
        </p>

        <form novalidate @submit.prevent="submitPassword">
          <div class="inputContainer">
            <AuthInput
              type="password"
              name="oldpassword"
              placeholder="Current password..."
              aria-label="Current password"
              autocomplete="current-password"
              :has-error="!!passwordErrors.oldPassword"
              @input="passwordErrors.oldPassword = ''"
            />
            <AuthInput
              type="password"
              name="newpassword"
              placeholder="New password..."
              aria-label="New password"
              autocomplete="new-password"
              :has-error="!!passwordErrors.newPassword"
              @input="passwordErrors.newPassword = ''"
            />
          </div>

          <div v-if="hasPasswordErrors" class="errorText">
            <p v-if="passwordErrors.oldPassword">{{ passwordErrors.oldPassword }}</p>
            <p v-if="passwordErrors.newPassword">{{ passwordErrors.newPassword }}</p>
          </div>

          <div class="buttonRow">
            <SubmitButton type="submit" :disabled="isSubmitting">Change password</SubmitButton>
            <span class="spinnerSlot" aria-hidden="true">
              <SpinnerLoader v-if="isSubmitting" :size="20" fgColor="var(--text-2)" />
            </span>
          </div>
        </form>
      </template>

      <template v-else-if="step === 'delete'">
        <h1>Delete your account?</h1>
        <p class="description">
          Your account will be permanently deleted and can't be recovered. This takes effect
          immediately.
        </p>
        <p class="description">The following will also be permanently deleted:</p>
        <ul class="consequences">
          <li>Your posts</li>
          <li>Your comments</li>
          <li>Your moons</li>
          <li>Your votes</li>
        </ul>

        <div class="buttonRow">
          <RouterLink class="cancelButton" to="/settings">No, take me back</RouterLink>
          <SubmitButton variant="danger" :disabled="isSubmitting" @click="deleteAccount">
            Yes, delete my account
          </SubmitButton>
          <span class="spinnerSlot" aria-hidden="true">
            <SpinnerLoader v-if="isSubmitting" :size="20" fgColor="var(--text-2)" />
          </span>
        </div>
      </template>
    </section>
  </main>
</template>

<style scoped>
main {
  width: 40rem;
}

h1 {
  margin-bottom: 1.5rem;
}

.notice {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin-bottom: 1rem;
}

.notice span {
  color: var(--text-2);
}

.settingsList {
  border: 1px solid var(--bg-2);
  border-radius: 0.75rem;
  background-color: var(--bg-sub);
  overflow: hidden;
}

.settingRow {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem 1.25rem;
  text-decoration: none;
}

.settingRow + .settingRow {
  border-top: 1px solid var(--bg-2);
}

.settingRow:hover {
  background-color: var(--bg-1);
}

.rowText {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  min-width: 0;
}

.rowTitle {
  font-weight: bold;
}

.rowDescription {
  font-size: 0.9rem;
  color: var(--text-2);
  overflow-wrap: anywhere;
}

.rowAction {
  flex-shrink: 0;
  padding: 0.35rem 0.75rem;
  font-size: 0.9rem;
  border-radius: 10px;
  background: var(--bg-2);
}

.danger .rowTitle,
.danger .rowAction {
  color: var(--text-error);
}

.backButton {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  margin-bottom: 1.5rem;
  margin-left: -0.5rem;
  padding: 0.35rem 0.6rem;
  border-radius: 10px;
  text-decoration: none;
}

.backButton span {
  color: var(--text-2);
}

.backButton:hover {
  background: var(--bg-2);
}

.description {
  color: var(--text-2);
  margin-bottom: 1rem;
}

.description strong {
  color: var(--text-1);
  overflow-wrap: anywhere;
}

.consequences {
  margin: -0.25rem 0 1.5rem 1.25rem;
}

.consequences li {
  color: var(--text-2);
  line-height: 1.5;
}

.inputContainer {
  display: flex;
  flex-direction: column;
  max-width: 24rem;
}

.errorText {
  font-size: 0.75rem;
  margin-top: 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.errorText p {
  color: var(--text-error);
}

.buttonRow {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 1rem;
}

.spinnerSlot {
  width: 20px;
  height: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.cancelButton {
  display: inline-flex;
  align-items: center;
  height: 2.25rem;
  padding: 0.5rem 0.75rem;
  border-radius: 10px;
  background: var(--bg-2);
  text-decoration: none;
}

.cancelButton:hover {
  background: var(--bg-3);
}
</style>
