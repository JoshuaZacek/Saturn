<template>
  <div
    ref="accountCard"
    :class="['accountCard', !isMenuClosed ? 'open' : '']"
    @click="isMenuClosed = false"
    @keyup.space="isMenuClosed = !isMenuClosed"
    @keyup.enter="isMenuClosed = !isMenuClosed"
    @keyup.up="isMenuClosed = false"
    @keyup.down="isMenuClosed = true"
    @keyup.escape="isMenuClosed = true"
    tabindex="0"
  >
    <div class="header">
      <p>{{ headerText }}</p>
      <CaretIcon
        class="caret"
        color="var(--text-2)"
        :direction="isMenuClosed ? 'up' : 'down'"
        @click.stop="closeMenu"
      />
    </div>

    <Transition
      @before-enter="beforeMenuEnter"
      @enter="enterMenu"
      @before-leave="beforeMenuLeave"
      @leave="leaveMenu"
    >
      <div class="menuContent" v-if="!isMenuClosed" ref="menuContent">
        <template v-if="!authStore.loggedIn">
          <form ref="form" @submit.prevent="handleSubmit">
            <div class="inputContainer">
              <AuthInput
                v-if="createOrLogin === 'signup'"
                type="text"
                name="username"
                placeholder="Username..."
                spellcheck="false"
                @keyup.enter.stop
                @keyup.space.stop
                @input="errors.username = ''"
                :hasError="!isSubmitting && !!errors.username"
              />
              <AuthInput
                type="email"
                name="email"
                placeholder="Email..."
                @keyup.enter.stop
                @keyup.space.stop
                @input="errors.email = ''"
                :hasError="!isSubmitting && !!errors.email"
              />
              <AuthInput
                type="password"
                name="password"
                placeholder="Password..."
                @keyup.enter.stop
                @keyup.space.stop
                @input="errors.password = ''"
                :hasError="!isSubmitting && !!errors.password"
              />
            </div>

            <Transition name="error-expand" :css="!isModeSwitching">
              <div
                class="errorText"
                v-if="!isSubmitting && (errors.password || errors.email || errors.username)"
              >
                <p v-if="!!errors.username">{{ errors.username }}</p>
                <p v-if="!!errors.email">{{ errors.email }}</p>
                <p v-if="!!errors.password">{{ errors.password }}</p>
              </div>
            </Transition>

            <div class="buttonContainer">
              <button class="submitButton" type="submit" :disabled="isSubmitting">
                {{ createOrLogin === 'login' ? 'Log in' : 'Sign up' }}
              </button>

              <span class="spinnerSlot" aria-hidden="true">
                <Transition name="spinner-fade">
                  <SpinnerLoader
                    v-if="isSubmitting"
                    :size="20"
                    bgColor="var(--bg-main)"
                    fgColor="var(--text-2)"
                  />
                </Transition>
              </span>
            </div>
          </form>

          <button class="toggleButton" @keyup.stop @click.stop="toggleCreateOrLogin">
            {{ createOrLogin === 'login' ? "Don't" : 'Already' }} have an account?
          </button>
        </template>

        <template v-else>
          <button class="submitButton" style="margin-top: -0.25rem" @click.stop="handleLogout">
            Log out
          </button>
        </template>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.accountCard {
  position: sticky;
  bottom: 0;
  width: 100%;
  margin-top: auto;
  margin-bottom: 0;
  min-height: 3.5rem;
  padding: 0.75rem 1rem;
  border: 1px solid var(--bg-2);
  border-radius: 0.5rem 0.5rem 0 0;
  box-shadow: 0 5px 20px rgb(0 0 0 / 10%);
  background: var(--bg-1);
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-direction: column;
}
.open {
  background: var(--bg-sub);
  cursor: default;
}
.submitButton {
  background-color: var(--bg-2);
  border: none;
  font-size: 1rem;
  padding: 0.5rem 0.75rem;
  border-radius: 10px;
  cursor: pointer;
}

.buttonContainer {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  margin-top: 1rem;
  margin-bottom: 0.25rem;
}

.spinnerSlot {
  width: 20px;
  height: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.accountCard:hover .caret {
  background-color: var(--bg-2);
}

.accountCard.open:hover .caret {
  background-color: var(--bg-sub);
}

p {
  color: var(--text-2);
}

.open p {
  color: var(--text-1);
}

.caret {
  margin-left: auto;
  margin-right: -0.25rem;
  padding: 0.25rem;
  box-sizing: content-box;
  background-color: var(--bg-1);
  border-radius: 10px;
  cursor: pointer;
}

.open .caret {
  background-color: var(--bg-sub);
}
.open .caret:hover {
  background-color: var(--bg-2) !important;
}

.header {
  display: flex;
  align-items: center;
  width: 100%;
}

.menuContent {
  margin-top: 1rem;
  width: 100%;
}

.toggleButton {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-2);
  font-size: 0.75rem;
}
.toggleButton:hover {
  text-decoration: underline;
}

.inputContainer {
  display: flex;
  flex-direction: column;
  margin-top: -0.25rem;
}

.errorText {
  font-size: 0.75rem;
  margin-top: 0.5rem;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.errorText p {
  color: var(--text-error) !important;
}

.spinner-fade-enter-active,
.spinner-fade-leave-active {
  transition: opacity 200ms ease;
}

.spinner-fade-enter-from,
.spinner-fade-leave-to {
  opacity: 0;
}

.error-expand-enter-active,
.error-expand-leave-active {
  transition:
    max-height 180ms ease,
    opacity 160ms ease,
    margin-top 180ms ease;
}

.error-expand-enter-from,
.error-expand-leave-to {
  max-height: 0;
  opacity: 0;
  margin-top: 0;
}

.error-expand-enter-to,
.error-expand-leave-from {
  max-height: 8rem;
  opacity: 1;
  margin-top: 0.5rem;
}
</style>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, useTemplateRef, watch } from 'vue'
import CaretIcon from './icons/CaretIcon.vue'
import axios from 'axios'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthInput from './AuthInput.vue'
import SpinnerLoader from './SpinnerLoader.vue'

const isMenuClosed = ref(true)
const errors = ref({
  username: '',
  email: '',
  password: '',
})
const isSubmitting = ref(false)
const isModeSwitching = ref(false)
const accountCard = useTemplateRef<HTMLDivElement>('accountCard')
const form = useTemplateRef<HTMLFormElement>('form')
const menuContent = useTemplateRef<HTMLDivElement>('menuContent')
const createOrLogin = ref<'login' | 'signup'>('login')
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
const LOCAL_VALIDATION_DELAY_MS = 450
const MENU_TRANSITION_MS = 220
let menuHeightAnimation: Animation | null = null
const router = useRouter()
const authStore = useAuthStore()
const headerText = computed(() => {
  return authStore.loggedIn && authStore.user.username
    ? '@' + authStore.user.username
    : 'Log in or Sign up'
})

const closeMenu = () => {
  if (!isMenuClosed.value) {
    isMenuClosed.value = true
  } else {
    isMenuClosed.value = false
  }
}

const handleDocumentPointerDown = (event: PointerEvent) => {
  const root = accountCard.value
  if (!root || isMenuClosed.value) {
    return
  }

  const target = event.target as Node | null
  if (!target || root.contains(target)) {
    return
  }

  isMenuClosed.value = true
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentPointerDown)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', handleDocumentPointerDown)
})

const clearErrors = () => {
  errors.value.username = ''
  errors.value.email = ''
  errors.value.password = ''
}

const animateModeSwitchHeight = async (updateMode: () => void) => {
  const menu = menuContent.value
  if (!menu || isMenuClosed.value) {
    updateMode()
    return
  }

  const startHeight = menu.getBoundingClientRect().height

  updateMode()
  await nextTick()

  const targetHeight = menu.scrollHeight
  if (Math.abs(targetHeight - startHeight) < 1) {
    menu.style.height = 'auto'
    menu.style.overflow = ''
    return
  }

  menuHeightAnimation?.cancel()
  menu.style.overflow = 'hidden'
  menu.style.height = `${startHeight}px`

  if (typeof menu.animate === 'function') {
    const animation = menu.animate(
      [{ height: `${startHeight}px` }, { height: `${targetHeight}px` }],
      {
        duration: MENU_TRANSITION_MS,
        easing: 'ease',
      },
    )
    menuHeightAnimation = animation

    try {
      await animation.finished
    } catch {
      // Ignore cancellation when a new mode switch starts mid-animation.
    }

    if (menuHeightAnimation === animation) {
      menu.style.height = 'auto'
      menu.style.overflow = ''
      menuHeightAnimation = null
    }
    return
  }

  await new Promise<void>((resolve) => {
    menu.style.transition = `height ${MENU_TRANSITION_MS}ms ease`

    const onTransitionEnd = (event: TransitionEvent) => {
      if (event.propertyName !== 'height') {
        return
      }

      menu.style.height = 'auto'
      menu.style.overflow = ''
      menu.style.transition = ''
      menu.removeEventListener('transitionend', onTransitionEnd)
      resolve()
    }

    menu.addEventListener('transitionend', onTransitionEnd)

    requestAnimationFrame(() => {
      menu.style.height = `${targetHeight}px`
    })
  })
}

const toggleCreateOrLogin = async () => {
  if (isModeSwitching.value) {
    return
  }

  isModeSwitching.value = true

  await animateModeSwitchHeight(() => {
    clearErrors()
    createOrLogin.value = createOrLogin.value === 'login' ? 'signup' : 'login'
  })

  await nextTick()
  isModeSwitching.value = false
}

const resetForm = () => {
  const currentForm = form.value
  if (currentForm) {
    currentForm.reset()
  }
  clearErrors()
  createOrLogin.value = 'login'
}

watch(isMenuClosed, (closed) => {
  if (closed) {
    resetForm()
    isSubmitting.value = false
  }
})

const hasOutstandingErrors = () => Object.values(errors.value).some((error) => !!error)
const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

const beforeMenuEnter = (el: Element) => {
  const menu = el as HTMLElement
  menu.dataset.targetMarginTop = getComputedStyle(menu).marginTop
  menu.style.height = '0'
  menu.style.marginTop = '0'
  menu.style.opacity = '0'
  menu.style.overflow = 'hidden'
}

const enterMenu = (el: Element) => {
  const menu = el as HTMLElement
  const targetMarginTop = menu.dataset.targetMarginTop ?? '0px'
  menu.style.transition = `height ${MENU_TRANSITION_MS}ms ease, opacity ${MENU_TRANSITION_MS}ms ease, margin-top ${MENU_TRANSITION_MS}ms ease`

  requestAnimationFrame(() => {
    menu.style.height = `${menu.scrollHeight}px`
    menu.style.marginTop = targetMarginTop
    menu.style.opacity = '1'
  })

  const onTransitionEnd = (event: TransitionEvent) => {
    if (event.propertyName !== 'height') {
      return
    }

    menu.style.height = 'auto'
    menu.style.marginTop = ''
    menu.style.overflow = ''
    menu.style.transition = ''
    menu.removeEventListener('transitionend', onTransitionEnd)
  }

  menu.addEventListener('transitionend', onTransitionEnd)
}

const beforeMenuLeave = (el: Element) => {
  const menu = el as HTMLElement
  menu.style.height = `${menu.scrollHeight}px`
  menu.style.marginTop = getComputedStyle(menu).marginTop
  menu.style.opacity = '1'
  menu.style.overflow = 'hidden'
}

const leaveMenu = (el: Element) => {
  const menu = el as HTMLElement
  menu.style.transition = `height ${MENU_TRANSITION_MS}ms ease, opacity ${MENU_TRANSITION_MS}ms ease, margin-top ${MENU_TRANSITION_MS}ms ease`

  requestAnimationFrame(() => {
    menu.style.height = '0'
    menu.style.marginTop = '0'
    menu.style.opacity = '0'
  })
}

const handleLogout = () => {
  axios.delete(`${backendUrl}/user/logout`).then(() => {
    authStore.logout()
    router.go(0)
  })
}

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

  if (hasOutstandingErrors()) {
    isSubmitting.value = false
    return
  }

  const emailField = currentForm.elements.namedItem('email') as HTMLInputElement | null
  const usernameField = currentForm.elements.namedItem('username') as HTMLInputElement | null
  const passwordField = currentForm.elements.namedItem('password') as HTMLInputElement | null
  const email = emailField?.value.trim() ?? ''
  const username = usernameField?.value ?? ''
  const password = passwordField?.value ?? ''

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
  } else if (password && password.length < 8 && createOrLogin.value === 'signup') {
    errors.value.password = 'Your password must contain 8 characters or more'
    isValid = false
  }

  if (createOrLogin.value === 'signup' && !username.trim()) {
    errors.value.username = 'Username is required'
    isValid = false
  } else if (!/^\w+$/.test(username) && username && createOrLogin.value === 'signup') {
    errors.value.username = 'Usernames can only contain letters, numbers and underscores'
    isValid = false
  }

  if (!isValid) {
    isSubmitting.value = false
    return
  }

  const formData = new FormData(currentForm)

  const endpoint = createOrLogin.value === 'signup' ? '/user/create' : '/user/login'

  try {
    const res = await axios.post(`${backendUrl}${endpoint}`, formData)

    authStore.login(res.data)
    router.go(0)
  } catch (err) {
    if (axios.isAxiosError(err) && err.response?.status == 400) {
      errors.value.email = err.response.data.errors?.email?.[0]
      errors.value.username = err.response.data.errors?.username?.[0]
      errors.value.password = err.response.data.errors?.password?.[0]
    } else {
      alert(createOrLogin.value === 'signup' ? "Couldn't sign up" : "Couldn't log in")
    }
  } finally {
    isSubmitting.value = false
  }
}
</script>
