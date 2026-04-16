import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

const AUTH_STORAGE_KEY = 'auth-user'

type AuthUser = {
  username?: string
  email?: string
  [key: string]: unknown
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser>({})
  const loggedIn = ref(false)

  const hydrateFromStorage = () => {
    const storedUser = localStorage.getItem(AUTH_STORAGE_KEY)

    if (!storedUser) {
      return
    }

    try {
      user.value = JSON.parse(storedUser) as AuthUser
      loggedIn.value = true
    } catch {
      localStorage.removeItem(AUTH_STORAGE_KEY)
    }
  }

  const login = (nextUser: AuthUser) => {
    user.value = nextUser
    loggedIn.value = true
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(nextUser))
  }

  const logout = () => {
    user.value = {}
    loggedIn.value = false
    localStorage.removeItem(AUTH_STORAGE_KEY)
  }

  const changeEmail = (newEmail: string) => {
    user.value = {
      ...user.value,
      email: newEmail,
    }
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(user.value))
  }

  const isLoggedIn = computed(() => loggedIn.value)
  const getUser = computed(() => user.value)

  hydrateFromStorage()

  return {
    user,
    loggedIn,
    login,
    logout,
    changeEmail,
    isLoggedIn,
    getUser,
  }
})
