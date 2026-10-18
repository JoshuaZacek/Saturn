<script setup lang="ts">
import { watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppSidebar from '@/components/AppSidebar.vue'
import ErrorBanner from '@/components/ErrorBanner.vue'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useUIStore } from '@/stores/ui'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()

// Errors belong to the page they happened on.
watch(
  () => route.fullPath,
  () => errorBanner.dismiss(),
)

// Leave pages that need a login (settings, create) once the session turns out
// to be gone; the account card explains what happened.
watch(
  () => authStore.sessionExpired,
  (expired) => {
    const message = route.meta.unauthorizedMessage
    if (expired && typeof message === 'string') {
      void router.replace({ name: 'unauthorized', query: { message } })
    }
  },
)
</script>

<template>
  <AppSidebar />
  <main class="page-content">
    <div
      v-if="errorBanner.message"
      class="errorBannerHost"
      :style="{ left: `${uiStore.sidebarWidthPx}px` }"
    >
      <ErrorBanner :message="errorBanner.message" @dismiss="errorBanner.dismiss" />
    </div>
    <RouterView />
  </main>
</template>

<style>
:root {
  --bg-1: #faf9f6; /* main background color */
  --bg-2: #ede9de; /* used for borders and some backgrounds */
  --bg-3: #d7cfb7; /* used for some backgrounds */
  --bg-error: #ff9999; /* error color */
  --bg-sub: #ffffff; /* used rarely to focus attention on content i.e. posts */

  --text-1: #14110b; /* main text color */
  --text-2: #625737; /* secondary text color, used for things like dates and usernames */
  --text-3: #918973; /* lighter text, used for placeholders */
  --text-error: #ff3333; /* error color */

  --vote-up: #96b85d; /* upvote color */
  --vote-down: #ff6501; /* downvote color */

  --accent-color: #ff741a; /* used for interactive elements like buttons and links */
  --accent-text: #ffffff; /* text color for elements with accent-color background */
}

html,
body,
#app {
  background-color: var(--bg-1);
  width: 100%;
  height: 100%;
  position: relative;
}

* {
  margin: 0;
  padding: 0;
  font-family: Helvetica, Arial, sans-serif;
  box-sizing: border-box;
  color: var(--text-1);
}
*:focus {
  outline: none;
}

*:focus-visible {
  outline: 2px solid var(--accent-color);
  outline-offset: 1px;
}

#app {
  display: flex;
}

.page-content {
  flex: 1;
  display: flex;
  justify-content: center;
  padding-top: 5rem;
  overflow-y: scroll;
}

.errorBannerHost {
  position: fixed;
  top: 1rem;
  right: 0;
  z-index: 20;
  display: flex;
  justify-content: center;
  padding: 0 1rem;
  pointer-events: none;
}

.errorBannerHost > * {
  max-width: 40rem;
  pointer-events: auto;
}
</style>
