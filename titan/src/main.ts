import { createApp } from 'vue'
import { createPinia } from 'pinia'
import axios from 'axios'

import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'

axios.defaults.withCredentials = true

const app = createApp(App)

app.use(createPinia())
app.use(router)

const authStore = useAuthStore()

// A 403 means either "no session" or "not yours" (e.g. deleting someone else's
// post), so when one arrives while we think we're logged in, ask /user/me which.
axios.interceptors.response.use(undefined, async (error) => {
  if (
    axios.isAxiosError(error) &&
    error.response?.status === 403 &&
    authStore.isLoggedIn &&
    !error.config?.url?.endsWith('/user/me')
  ) {
    await authStore.verifySession()
  }

  return Promise.reject(error)
})

// The stored login may be stale (expired session, logged out elsewhere).
void authStore.verifySession()

app.mount('#app')
