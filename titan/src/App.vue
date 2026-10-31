<script setup lang="ts">
import { watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppSidebar from '@/components/AppSidebar.vue'
import AppTopBar from '@/components/AppTopBar.vue'
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
  <AppTopBar v-if="uiStore.isCompactLayout" />
  <AppSidebar />
  <main
    class="page-content"
    :class="{ fullWidth: route.meta.fullWidth, compact: uiStore.isCompactLayout }"
    :inert="uiStore.isCompactLayout && uiStore.isSidebarOpen"
  >
    <div
      v-if="errorBanner.message"
      class="errorBannerHost"
      :style="uiStore.isCompactLayout ? undefined : { left: `${uiStore.sidebarWidthPx}px` }"
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

  --top-bar-height: 3.5rem; /* the top bar that replaces the sidebar on small screens */
}

html,
body,
#app {
  background-color: var(--bg-1);
  width: 100%;
  height: 100%;
  position: relative;
}

html {
  /* Keeps iOS from enlarging text when a phone is turned sideways. */
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
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

/* Pages are up to 40rem wide and shrink to fit between the gutters. */
.page-content {
  flex: 1;
  display: flex;
  justify-content: center;
  padding: 5rem 1rem 0;
  overflow-y: scroll;
}

/* Below the fixed top bar, which already takes up some of the space above. */
.page-content.compact {
  margin-top: var(--top-bar-height);
  padding-top: 1.5rem;
}

.page-content.fullWidth {
  padding-top: 0;
}

.errorBannerHost {
  position: fixed;
  top: 1rem;
  left: 0;
  right: 0;
  z-index: 20;
  display: flex;
  justify-content: center;
  padding: 0 1rem;
  pointer-events: none;
}

.compact .errorBannerHost {
  top: calc(var(--top-bar-height) + 0.75rem);
}

.errorBannerHost > * {
  max-width: 40rem;
  pointer-events: auto;
}
</style>
