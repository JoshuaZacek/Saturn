import axios from 'axios'
import { ref } from 'vue'
import { defineStore } from 'pinia'

export interface SubscribedMoon {
  id: number
  name: string
}

const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

const apiBase = () => {
  if (!backendUrl) {
    throw new Error('VITE_BACKEND_URL is not set')
  }

  return backendUrl.replace(/\/$/, '')
}

// Same order as `GET /subscriptions`: by name, ignoring case.
const byName = (a: SubscribedMoon, b: SubscribedMoon) =>
  a.name.toLowerCase().localeCompare(b.name.toLowerCase())

// The logged-in user's moon subscriptions, shared by the sidebar list and
// the subscribe button on moon pages.
export const useSubscriptionsStore = defineStore('subscriptions', () => {
  const moons = ref<SubscribedMoon[]>([])
  const hasLoaded = ref(false)

  const load = async () => {
    try {
      const response = await axios.get<{ moons: SubscribedMoon[] }>(`${apiBase()}/subscriptions`)
      moons.value = response.data.moons
    } catch {
      // The list is a shortcut; the moon pages still work without it.
      moons.value = []
    } finally {
      hasLoaded.value = true
    }
  }

  const clear = () => {
    moons.value = []
    hasLoaded.value = false
  }

  // Throws if the request fails, so the caller can report it.
  const setSubscribed = async (moon: SubscribedMoon, subscribed: boolean) => {
    if (subscribed) {
      await axios.post(`${apiBase()}/subscription`, { moon_id: moon.id })
      if (!moons.value.some((m) => m.id === moon.id)) {
        moons.value = [...moons.value, { id: moon.id, name: moon.name }].sort(byName)
      }
    } else {
      await axios.delete(`${apiBase()}/subscription`, { params: { moon_id: moon.id } })
      moons.value = moons.value.filter((m) => m.id !== moon.id)
    }
  }

  return {
    moons,
    hasLoaded,
    load,
    clear,
    setSubscribed,
  }
})
