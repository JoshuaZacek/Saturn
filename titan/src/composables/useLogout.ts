import axios from 'axios'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Logs out on the server, then locally, and reloads so every page starts over
// without the session. A failed request (e.g. the session already expired)
// still logs out locally, so nobody gets stuck logged in.
export const useLogout = () => {
  const router = useRouter()
  const authStore = useAuthStore()
  const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

  return async () => {
    try {
      await axios.delete(`${backendUrl}/user/logout`)
    } catch {
      // Log out locally anyway.
    } finally {
      authStore.logout()
      router.go(0)
    }
  }
}
