import axios from 'axios'
import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

const AUTH_STORAGE_KEY = 'auth-user'
const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

type AuthUser = {
  username?: string
  email?: string
  [key: string]: unknown
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser>({})
  const loggedIn = ref(false)
  // Set when a stored login turns out to have no valid session behind it.
  const sessionExpired = ref(false)

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
    sessionExpired.value = false
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

  let verifyingSession: Promise<boolean> | null = null

  // Asks the API who the session cookie belongs to and refreshes the stored
  // user. If the session is gone (expired, logged out elsewhere, account
  // deleted), logs out locally and flags `sessionExpired`. Network errors keep
  // the stored login. Concurrent callers share one request.
  const verifySession = () => {
    if (!loggedIn.value || !backendUrl) {
      return Promise.resolve(loggedIn.value)
    }

    verifyingSession ??= (async () => {
      try {
        const base = backendUrl.replace(/\/$/, '')
        const response = await axios.get<AuthUser>(`${base}/user/me`)
        login(response.data)
        return true
      } catch (err) {
        if (axios.isAxiosError(err) && err.response?.status === 403) {
          logout()
          sessionExpired.value = true
          return false
        }

        return true
      } finally {
        verifyingSession = null
      }
    })()

    return verifyingSession
  }

  const clearSessionExpired = () => {
    sessionExpired.value = false
  }

  const isLoggedIn = computed(() => loggedIn.value)
  const getUser = computed(() => user.value)

  hydrateFromStorage()

  return {
    user,
    loggedIn,
    sessionExpired,
    login,
    logout,
    changeEmail,
    verifySession,
    clearSessionExpired,
    isLoggedIn,
    getUser,
  }
})
