<script setup lang="ts">
import axios from 'axios'
import { computed, nextTick, ref, useTemplateRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AvatarEditor from '@/components/AvatarEditor.vue'
import PageHeader from '@/components/PageHeader.vue'
import SegmentedControl from '@/components/SegmentedControl.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import CaretLeftIcon from '@/components/icons/CaretLeftIcon.vue'
import CaretRightIcon from '@/components/icons/CaretRightIcon.vue'
import CheckIcon from '@/components/icons/CheckIcon.vue'
import { waitForMinimumVisibleTime } from '@/config/loading'
import { useAuthStore } from '@/stores/auth'
import { useAvatarStore } from '@/stores/avatars'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore, type Theme } from '@/stores/ui'
import type { AvatarFields } from '@/utils/avatar'

type Step = 'email' | 'password' | 'delete'

const EMAIL_PATTERN = /.+@(?=[^@]+$).+\.(?=[^.]+$)/
const PASSWORD_MIN_LENGTH = 8

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()
const avatarStore = useAvatarStore()

const username = computed(() => String(authStore.user.username ?? ''))
const isEditingAvatar = ref(false)
const currentAvatar = computed<AvatarFields>(() => ({
  avatar_color: authStore.user.avatar_color ?? '',
  avatar_image: authStore.user.avatar_image ?? null,
}))

const onAvatarSaved = (avatar: AvatarFields) => {
  isEditingAvatar.value = false
  authStore.changeAvatar(avatar)
  avatarStore.change('user', username.value, avatar)
}

const themeOptions: { label: string; value: Theme }[] = [
  { label: 'System', value: 'system' },
  { label: 'Light', value: 'light' },
  { label: 'Dark', value: 'dark' },
]
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
const passwordErrors = ref({ oldPassword: '', newPassword: '', confirmPassword: '' })

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
  passwordErrors.value = { oldPassword: '', newPassword: '', confirmPassword: '' }
  isSubmitting.value = false

  if (!nextStep) {
    return
  }

  notice.value = ''
  await nextTick()
  // The first field, or on the delete step, the safe choice.
  stepSection.value?.querySelector<HTMLElement>('input, .cancelButton')?.focus()
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
  const confirmPassword = String(formData.get('confirmpassword') ?? '')
  const nextErrors = { oldPassword: '', newPassword: '', confirmPassword: '' }

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

  if (!confirmPassword) {
    nextErrors.confirmPassword = 'Please confirm your new password'
  } else if (newPassword && confirmPassword !== newPassword) {
    nextErrors.confirmPassword = "Passwords don't match"
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
  <main class="settingsPage">
    <template v-if="!step">
      <PageHeader title="Settings" />

      <p v-if="notice" class="notice" role="status">
        <CheckIcon :size="18" color="var(--success)" />
        <span>{{ notice }}</span>
      </p>

      <h2 class="groupTitle">Appearance</h2>
      <div class="settingsList">
        <div class="settingRow staticRow">
          <span class="rowTitle">Theme</span>
          <SegmentedControl
            class="themeControl"
            size="sm"
            label="Theme"
            :model-value="uiStore.theme"
            :options="themeOptions"
            @update:model-value="uiStore.setTheme($event as Theme)"
          />
        </div>
      </div>

      <h2 class="groupTitle">Account</h2>
      <div class="settingsList">
        <button class="settingRow" type="button" @click="isEditingAvatar = true">
          <span class="rowTitle">Profile picture</span>
          <UserAvatar
            class="rowAvatar"
            :name="username"
            :color="authStore.user.avatar_color"
            :image="authStore.user.avatar_image"
            :size="32"
          />
          <CaretRightIcon class="chevron" />
        </button>

        <RouterLink class="settingRow" :to="{ name: 'settings', params: { step: 'email' } }">
          <span class="rowTitle">Email</span>
          <span class="rowValue">{{ authStore.user.email }}</span>
          <CaretRightIcon class="chevron" />
        </RouterLink>

        <RouterLink class="settingRow" :to="{ name: 'settings', params: { step: 'password' } }">
          <span class="rowTitle">Password</span>
          <CaretRightIcon class="chevron" />
        </RouterLink>

        <RouterLink
          class="settingRow danger"
          :to="{ name: 'settings', params: { step: 'delete' } }"
        >
          <span class="rowTitle">Delete account</span>
          <CaretRightIcon class="chevron" />
        </RouterLink>
      </div>

      <AvatarEditor
        :open="isEditingAvatar"
        kind="user"
        :name="username"
        :avatar="currentAvatar"
        endpoint="/user/avatar"
        @close="isEditingAvatar = false"
        @saved="onAvatarSaved"
      />
    </template>

    <section v-else ref="stepSection" class="settingsStep">
      <RouterLink class="backLink" to="/settings">
        <CaretLeftIcon :size="16" />
        <span>Settings</span>
      </RouterLink>

      <template v-if="step === 'email'">
        <PageHeader title="Change email" />

        <form class="formCard" novalidate @submit.prevent="submitEmail">
          <div class="formField">
            <span class="fieldLabel">Current email</span>
            <p class="currentValue">{{ authStore.user.email }}</p>
          </div>

          <div class="formField">
            <label class="fieldLabel" for="newemail">New email</label>
            <input
              id="newemail"
              class="field"
              :class="{ error: !!emailErrors.newEmail }"
              type="email"
              name="newemail"
              autocomplete="email"
              :aria-invalid="!!emailErrors.newEmail || undefined"
              aria-describedby="newemail-message"
              @input="emailErrors.newEmail = ''"
            />
            <p id="newemail-message" class="fieldMessage error">{{ emailErrors.newEmail }}</p>
          </div>

          <div class="formField">
            <label class="fieldLabel" for="confirmemail">Confirm new email</label>
            <input
              id="confirmemail"
              class="field"
              :class="{ error: !!emailErrors.confirmEmail }"
              type="email"
              name="confirmemail"
              autocomplete="email"
              :aria-invalid="!!emailErrors.confirmEmail || undefined"
              aria-describedby="confirmemail-message"
              @input="emailErrors.confirmEmail = ''"
            />
            <p id="confirmemail-message" class="fieldMessage error">
              {{ emailErrors.confirmEmail }}
            </p>
          </div>

          <div class="formFooter">
            <RouterLink class="btn-secondary cancelButton" to="/settings">Cancel</RouterLink>
            <SubmitButton type="submit" :loading="isSubmitting">Change email</SubmitButton>
          </div>
        </form>
      </template>

      <template v-else-if="step === 'password'">
        <PageHeader title="Change password" />

        <form class="formCard" novalidate @submit.prevent="submitPassword">
          <div class="formField">
            <label class="fieldLabel" for="oldpassword">Current password</label>
            <input
              id="oldpassword"
              class="field"
              :class="{ error: !!passwordErrors.oldPassword }"
              type="password"
              name="oldpassword"
              autocomplete="current-password"
              :aria-invalid="!!passwordErrors.oldPassword || undefined"
              aria-describedby="oldpassword-message"
              @input="passwordErrors.oldPassword = ''"
            />
            <p id="oldpassword-message" class="fieldMessage error">
              {{ passwordErrors.oldPassword }}
            </p>
          </div>

          <div class="formField">
            <label class="fieldLabel" for="newpassword">New password</label>
            <input
              id="newpassword"
              class="field"
              :class="{ error: !!passwordErrors.newPassword }"
              type="password"
              name="newpassword"
              autocomplete="new-password"
              :aria-invalid="!!passwordErrors.newPassword || undefined"
              aria-describedby="newpassword-message"
              @input="passwordErrors.newPassword = ''"
            />
            <p
              id="newpassword-message"
              class="fieldMessage"
              :class="{ error: !!passwordErrors.newPassword }"
            >
              {{ passwordErrors.newPassword || `At least ${PASSWORD_MIN_LENGTH} characters.` }}
            </p>
          </div>

          <div class="formField">
            <label class="fieldLabel" for="confirmpassword">Confirm new password</label>
            <input
              id="confirmpassword"
              class="field"
              :class="{ error: !!passwordErrors.confirmPassword }"
              type="password"
              name="confirmpassword"
              autocomplete="new-password"
              :aria-invalid="!!passwordErrors.confirmPassword || undefined"
              aria-describedby="confirmpassword-message"
              @input="passwordErrors.confirmPassword = ''"
            />
            <p id="confirmpassword-message" class="fieldMessage error">
              {{ passwordErrors.confirmPassword }}
            </p>
          </div>

          <div class="formFooter">
            <RouterLink class="btn-secondary cancelButton" to="/settings">Cancel</RouterLink>
            <SubmitButton type="submit" :loading="isSubmitting">Change password</SubmitButton>
          </div>
        </form>
      </template>

      <template v-else-if="step === 'delete'">
        <PageHeader title="Delete your account?" />

        <div class="formCard">
          <div class="deleteCopy">
            <p>
              Your account will be permanently deleted and can't be recovered. This takes effect
              immediately.
            </p>
            <p>The following will also be permanently deleted:</p>
            <ul class="consequences">
              <li>Your posts</li>
              <li>Your comments</li>
              <li>Your moons</li>
              <li>Your votes</li>
            </ul>
          </div>

          <div class="formFooter">
            <RouterLink class="btn-secondary cancelButton" to="/settings">Cancel</RouterLink>
            <SubmitButton variant="danger" :loading="isSubmitting" @click="deleteAccount">
              Delete account
            </SubmitButton>
          </div>
        </div>
      </template>
    </section>
  </main>
</template>

<style scoped>
.settingsPage {
  width: 100%;
  max-width: var(--column-width);
}

.notice {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1.25rem;
  padding: 0.75rem 1rem;
  border-radius: var(--radius-lg);
  background-color: var(--surface);
  box-shadow: var(--shadow-sm);
  font-size: var(--text-subhead);
}

/* Just inside the card's edge. */
.groupTitle {
  margin: 0 0 0.45rem 0.375rem;
  font-size: var(--text-footnote);
  font-weight: 600;
  letter-spacing: 0;
  color: var(--text-3);
}

.settingsList + .groupTitle {
  margin-top: 2rem;
}

.settingsList {
  border-radius: var(--radius-lg);
  background-color: var(--surface);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

.settingRow {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-height: 3.25rem;
  padding: 0.6rem 0.9rem 0.6rem 1.25rem;
  color: inherit;
  text-decoration: none;
  transition: background-color var(--duration-fast) var(--ease-out);
}

/* Inset hairlines between rows. */
.settingRow + .settingRow::before {
  content: '';
  position: absolute;
  top: 0;
  left: 1.25rem;
  right: 0;
  height: 1px;
  background-color: var(--separator);
}

.settingRow:focus-visible {
  outline-offset: -2px;
  border-radius: var(--radius-lg);
}

/* Rows that open a sheet rather than a page. */
button.settingRow {
  width: 100%;
  border: none;
  background: none;
  font-size: var(--text-body);
  text-align: left;
  cursor: pointer;
}

@media (hover: hover) {
  a.settingRow:hover,
  button.settingRow:hover {
    background-color: var(--fill-hover);
  }
}

a.settingRow:active,
button.settingRow:active {
  background-color: var(--fill-pressed);
}

/* The current picture, where other rows show their value. */
.rowAvatar {
  margin-left: auto;
}

.rowAvatar + .chevron {
  margin-left: 0;
}

.rowTitle {
  flex-shrink: 0;
  font-weight: 500;
}

/* The current value, right-aligned before the chevron. */
.rowValue {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  text-align: right;
  color: var(--text-2);
}

.chevron {
  flex-shrink: 0;
  margin-left: auto;
  color: var(--text-3);
}

.rowValue + .chevron {
  margin-left: 0;
}

.danger .rowTitle {
  color: var(--danger);
}

/* A row that holds its own control rather than linking somewhere. */
.staticRow {
  justify-content: space-between;
  padding-right: 0.75rem;
}

.themeControl {
  flex-shrink: 0;
}

/* Phones: the theme control goes under its title, full width. */
@media (max-width: 480px) {
  .staticRow {
    flex-direction: column;
    align-items: stretch;
    gap: 0.6rem;
    padding: 0.85rem 1rem;
  }

  .settingRow.staticRow > .themeControl {
    width: 100%;
  }
}

.backLink {
  display: inline-flex;
  align-items: center;
  gap: 0.15rem;
  margin: -0.35rem 0 1.25rem -0.55rem;
  padding: 0.3rem 0.65rem 0.3rem 0.35rem;
  border-radius: var(--radius-full);
  color: var(--text-2);
  font-size: var(--text-subhead);
  font-weight: 500;
  text-decoration: none;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .backLink:hover {
    background-color: var(--fill-hover);
    color: var(--text-1);
  }
}

.backLink:active {
  background-color: var(--fill-pressed);
}

.currentValue {
  overflow-wrap: anywhere;
}

/* The same size as the button beside it. */
.cancelButton {
  min-height: var(--control-md);
  padding: 0 0.95rem;
  font-size: var(--text-body);
}

.deleteCopy {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  color: var(--text-2);
  line-height: 1.5;
}

.consequences {
  margin-left: 1.25rem;
}

.consequences li {
  line-height: 1.6;
}
</style>
