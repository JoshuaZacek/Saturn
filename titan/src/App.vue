<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppSidebar from '@/components/AppSidebar.vue'
import AppTopBar from '@/components/AppTopBar.vue'
import AuthSheet from '@/components/AuthSheet.vue'
import ErrorBanner from '@/components/ErrorBanner.vue'
import NotificationToasts from '@/components/NotificationToasts.vue'
import PageRouteScope from '@/components/PageRouteScope.vue'
import { useAuthStore } from '@/stores/auth'
import { useErrorBannerStore } from '@/stores/errorBanner'
import { useNotificationsStore } from '@/stores/notifications'
import { useUIStore } from '@/stores/ui'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const errorBanner = useErrorBannerStore()
const uiStore = useUIStore()
const notifications = useNotificationsStore()
const pageContent = ref<HTMLElement | null>(null)

// A new page starts at the top. This runs between the old page fading out and
// the new one fading in, so the jump is never seen.
const resetScroll = () => {
  if (pageContent.value) {
    pageContent.value.scrollTop = 0
  }
}

// Errors belong to the page they happened on.
watch(
  () => route.fullPath,
  () => errorBanner.dismiss(),
)

// Home is only for accounts; once logged out (or the session turns out to be
// gone), show today's top posts instead.
watch(
  () => authStore.isLoggedIn,
  (loggedIn) => {
    if (!loggedIn && route.name === 'home') {
      void router.replace({ name: 'all', query: { sort: 'top', t: 'day' } })
    }
  },
)

// Notifications (the bell, live updates and pop-ups) run while logged in.
watch(
  () => authStore.isLoggedIn,
  (loggedIn) => (loggedIn ? notifications.start() : notifications.stop()),
  { immediate: true },
)

// When the session turns out to be gone, offer to log in again (the sheet
// says what happened), and leave pages that need a login (settings, create).
watch(
  () => authStore.sessionExpired,
  (expired) => {
    if (!expired) {
      return
    }

    uiStore.openAuth('login')
    const message = route.meta.unauthorizedMessage
    if (typeof message === 'string') {
      void router.replace({ name: 'unauthorized', query: { message } })
    }
  },
)

const runErrorAction = () => {
  const action = errorBanner.action
  errorBanner.dismiss()
  action?.run()
}
</script>

<template>
  <AppTopBar v-if="uiStore.isCompactLayout" />
  <AppSidebar />
  <!-- Each page brings its own <main>; this is only the scrolling column. -->
  <div
    ref="pageContent"
    class="page-content"
    :class="{ compact: uiStore.isCompactLayout }"
    :inert="uiStore.isCompactLayout && uiStore.isSidebarOpen"
  >
    <Transition name="error-banner">
      <div
        v-if="errorBanner.message"
        class="errorBannerHost"
        :style="uiStore.isCompactLayout ? undefined : { left: `${uiStore.sidebarWidthPx}px` }"
      >
        <ErrorBanner
          :message="errorBanner.message"
          :action-label="errorBanner.action?.label"
          @action="runErrorAction"
          @dismiss="errorBanner.dismiss"
        />
      </div>
    </Transition>
    <!-- Pages crossfade. Query changes (sort, filters) stay on the same page.
         The top padding is a class on each page, so a page fading out keeps
         its own spacing while the next one is on its way. -->
    <RouterView v-slot="{ Component, route: pageRoute }">
      <Transition name="page" mode="out-in" @after-leave="resetScroll">
        <PageRouteScope v-if="Component" :key="pageRoute.path">
          <component :is="Component" :class="{ pagePadded: !pageRoute.meta.centered }" />
        </PageRouteScope>
      </Transition>
    </RouterView>
  </div>
  <NotificationToasts v-if="authStore.isLoggedIn" :compact="uiStore.isCompactLayout" />
  <AuthSheet />
</template>

<style>
/* ---------------------------------------------------------------------------
   Design tokens
   --------------------------------------------------------------------------- */
:root {
  color-scheme: light;

  /* Type: the system UI face (San Francisco on Apple devices), on Apple's
     text-style scale for a 16px body. */
  --font-sans:
    -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, 'Helvetica Neue',
    Helvetica, Arial, sans-serif;
  --text-caption: 0.75rem; /* 12: counters, fine print */
  --text-footnote: 0.8125rem; /* 13: meta lines, section labels */
  --text-subhead: 0.9375rem; /* 15: controls, secondary copy */
  --text-body: 1rem; /* 16 */
  --text-reading: 1.0625rem; /* 17: post bodies on the post page */
  --text-title-3: 1.25rem; /* 20: card titles, section headings */
  --text-title-2: 1.5rem; /* 24 */
  --text-title-1: 1.75rem; /* 28: page titles */
  --tracking-tight: -0.022em; /* page titles */
  --tracking-snug: -0.012em; /* 20–24px headings */

  /* Backgrounds */
  --bg-1: #faf9f6; /* page background */
  --bg-2: #ede9de; /* quiet fills: segmented controls, secondary buttons */
  --bg-3: #d7cfb7; /* stronger fills: dashed outlines */
  --bg-sub: #ffffff; /* content surfaces such as posts */

  /* Text */
  --text-1: #14110b; /* primary */
  --text-2: #605b52; /* secondary: dates, usernames, descriptions */
  --text-3: #736e64; /* tertiary: placeholders, empty states (4.5:1 on the page) */

  /* Accent and status. The brand orange marks selection, focus and icons;
     filled buttons use a deeper orange so their white labels read at 4.7:1. */
  --accent-color: #ff741a;
  --accent-text: #ffffff; /* text on a filled button */
  --accent-fill: #c84a0a;
  --accent-fill-hover: color-mix(in srgb, var(--accent-fill) 90%, #000);
  --accent-fill-pressed: color-mix(in srgb, var(--accent-fill) 82%, #000);
  --accent-ink: #c2470a; /* orange text on light surfaces */
  --text-error: #d93a2b;
  --danger: var(--text-error);
  --danger-fill: #d93a2b;
  --danger-soft: color-mix(in srgb, var(--danger) 8%, var(--bg-sub));
  --bg-error: var(--danger-soft);
  --vote-up: #4f7a1f;
  --vote-down: #bf4a00;
  --success: var(--vote-up);

  /* Monogram avatars: one hue per name, as a soft tint. */
  --avatar-sat: 50%;
  --avatar-bg-l: 89%;
  --avatar-fg-l: 32%;

  /* Surfaces and fills */
  --surface: var(--bg-sub); /* cards */
  --surface-raised: var(--bg-sub); /* menus, popovers, banners */
  --fill-raised: var(
    --bg-sub
  ); /* a control raised off a filled area: selected segment, banner buttons */
  --fill-secondary: var(--bg-2); /* secondary buttons */
  --fill-secondary-hover: color-mix(in srgb, var(--bg-2) 70%, var(--bg-3));
  --fill-hover: color-mix(
    in srgb,
    var(--text-2) 5%,
    transparent
  ); /* hover: lighter than a selection */
  --fill-pressed: color-mix(in srgb, var(--text-2) 10%, transparent);
  --fill-capsule: color-mix(in srgb, var(--text-1) 5%, transparent); /* vote and comment counts */
  --fill-capsule-hover: color-mix(in srgb, var(--text-1) 9%, transparent);
  --separator: color-mix(in srgb, var(--text-1) 9%, transparent); /* hairlines */
  --separator-strong: color-mix(in srgb, var(--text-1) 15%, transparent); /* input borders */
  --backdrop: rgb(20 17 11 / 28%);
  --top-bar-bg: color-mix(in srgb, var(--bg-1) 82%, transparent);
  /* Tooltips: dark on the light page, for contrast. */
  --tooltip-bg: #2c2a26;
  --tooltip-text: #f7f5f0;
  --logo-filter: none; /* the logo is black line art; dark mode inverts it */

  /* Corner radii */
  --radius-xs: 6px; /* rows inside menus */
  --radius-sm: 8px; /* ghost and small buttons */
  --radius-md: 10px; /* buttons, inputs */
  --radius-lg: 0.75rem; /* cards */
  --radius-xl: 1.25rem; /* large form surfaces */
  --radius-full: 999px;

  /* Shadows: a hairline ring plus soft, warm, layered lift. */
  --shadow-rgb: 61 48 18;
  --shadow-sm:
    0 0 0 1px var(--separator), 0 1px 2px rgb(var(--shadow-rgb) / 4%),
    0 2px 8px rgb(var(--shadow-rgb) / 3%);
  --shadow-md:
    0 0 0 1px var(--separator), 0 1px 3px rgb(var(--shadow-rgb) / 6%),
    0 4px 12px rgb(var(--shadow-rgb) / 5%);
  --shadow-lg:
    0 0 0 1px var(--separator), 0 4px 12px rgb(var(--shadow-rgb) / 6%),
    0 12px 32px rgb(var(--shadow-rgb) / 10%);
  --focus-ring: 0 0 0 3px color-mix(in srgb, var(--accent-color) 30%, transparent);

  /* Motion */
  --ease-out: cubic-bezier(0.2, 0.8, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
  --duration-fast: 150ms;
  --duration-base: 200ms;
  --duration-slow: 280ms;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-5: 1.5rem;
  --space-6: 2rem;

  /* Control heights: compact (toolbars, menus), default (buttons), large
     (form submits). Touch screens get taller ones below. */
  --control-sm: 2rem;
  --control-md: 2.25rem;
  --control-lg: 2.75rem;

  /* Layout */
  --top-bar-height: 3.5rem; /* the top bar that replaces the sidebar on small screens */
  --column-width: 40rem; /* the reading column every page keeps to */
}

@media (pointer: coarse) {
  :root {
    --control-sm: 2.25rem;
    --control-md: 2.5rem;
  }
}

/* Dark palette: follows the system unless Settings picked light, or forced by
   Settings. The two blocks must stay identical. */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme='light']) {
    color-scheme: dark;
    /* Near-neutral greys with only a trace of warmth, so the orange accent and
       vote colours carry the identity rather than a brown cast. */
    --bg-1: #191817;
    --bg-2: #2c2b29;
    --bg-3: #42403d;
    --bg-sub: #222120;
    --text-1: #f2f1ee;
    --text-2: #a8a49d;
    --text-3: #8f8a82;
    --accent-color: #ff7a24;
    --accent-text: #ffffff;
    --accent-ink: #ff8a3d;
    --text-error: #ff6a5c;
    --danger-fill: #cf3a2e;
    --vote-up: #a3c66a;
    --vote-down: #ff7d2e;
    --avatar-sat: 32%;
    --avatar-bg-l: 27%;
    --avatar-fg-l: 82%;
    --surface-raised: #2a2927;
    --tooltip-bg: var(--surface-raised);
    --tooltip-text: var(--text-1);
    --fill-raised: #464441;
    --fill-secondary: rgb(255 255 255 / 8%); /* translucent, so it lifts on any surface */
    --fill-secondary-hover: rgb(255 255 255 / 12%);
    --fill-hover: rgb(255 255 255 / 4%);
    --fill-pressed: rgb(255 255 255 / 8%);
    --fill-capsule: rgb(255 255 255 / 6%);
    --fill-capsule-hover: rgb(255 255 255 / 10%);
    --separator: rgb(255 255 255 / 8%);
    --separator-strong: rgb(255 255 255 / 13%);
    --backdrop: rgb(0 0 0 / 50%);
    --logo-filter: invert(1);
    --shadow-rgb: 0 0 0;
    --shadow-sm: 0 0 0 1px var(--separator);
    --shadow-md: 0 0 0 1px var(--separator), 0 2px 6px rgb(0 0 0 / 25%);
    --shadow-lg:
      0 0 0 1px var(--separator-strong), 0 6px 16px rgb(0 0 0 / 30%), 0 16px 40px rgb(0 0 0 / 35%);
    --focus-ring: 0 0 0 3px color-mix(in srgb, var(--accent-color) 40%, transparent);
  }
}

:root[data-theme='dark'] {
  color-scheme: dark;
  /* Near-neutral greys with only a trace of warmth, so the orange accent and
     vote colours carry the identity rather than a brown cast. */
  --bg-1: #191817;
  --bg-2: #2c2b29;
  --bg-3: #42403d;
  --bg-sub: #222120;
  --text-1: #f2f1ee;
  --text-2: #a8a49d;
  --text-3: #8f8a82;
  --accent-color: #ff7a24;
  --accent-text: #ffffff;
  --accent-ink: #ff8a3d;
  --text-error: #ff6a5c;
  --danger-fill: #cf3a2e;
  --vote-up: #a3c66a;
  --vote-down: #ff7d2e;
  --avatar-sat: 32%;
  --avatar-bg-l: 27%;
  --avatar-fg-l: 82%;
  --surface-raised: #2a2927;
  --tooltip-bg: var(--surface-raised);
  --tooltip-text: var(--text-1);
  --fill-raised: #464441;
  --fill-secondary: rgb(255 255 255 / 8%); /* translucent, so it lifts on any surface */
  --fill-secondary-hover: rgb(255 255 255 / 12%);
  --fill-hover: rgb(255 255 255 / 4%);
  --fill-pressed: rgb(255 255 255 / 8%);
  --fill-capsule: rgb(255 255 255 / 6%);
  --fill-capsule-hover: rgb(255 255 255 / 10%);
  --separator: rgb(255 255 255 / 8%);
  --separator-strong: rgb(255 255 255 / 13%);
  --backdrop: rgb(0 0 0 / 50%);
  --logo-filter: invert(1);
  --shadow-rgb: 0 0 0;
  --shadow-sm: 0 0 0 1px var(--separator);
  --shadow-md: 0 0 0 1px var(--separator), 0 2px 6px rgb(0 0 0 / 25%);
  --shadow-lg:
    0 0 0 1px var(--separator-strong), 0 6px 16px rgb(0 0 0 / 30%), 0 16px 40px rgb(0 0 0 / 35%);
  --focus-ring: 0 0 0 3px color-mix(in srgb, var(--accent-color) 40%, transparent);
}

/* ---------------------------------------------------------------------------
   Base
   --------------------------------------------------------------------------- */
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
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  -webkit-tap-highlight-color: transparent;
}

body {
  color: var(--text-1);
  transition: background-color var(--duration-base) var(--ease-in-out);
}

* {
  margin: 0;
  padding: 0;
  font-family: var(--font-sans);
  box-sizing: border-box;
}

/* Form controls and links take the colour of where they sit. */
button,
input,
textarea,
select,
a {
  color: inherit;
}

h1 {
  font-size: var(--text-title-1);
  font-weight: 700;
  letter-spacing: var(--tracking-tight);
  line-height: 1.15;
}

h2 {
  letter-spacing: var(--tracking-snug);
}

h1,
h2,
h3 {
  text-wrap: balance;
}

::selection {
  background-color: color-mix(in srgb, var(--accent-color) 25%, transparent);
}

:focus:not(:focus-visible) {
  outline: none;
}

:focus-visible {
  outline: 2px solid var(--accent-color);
  outline-offset: 2px;
}

/* Text fields show focus with a soft ring instead of an outline. */
.field {
  width: 100%;
  border: 1px solid var(--separator-strong);
  border-radius: var(--radius-md);
  background-color: var(--bg-1);
  font-size: 1rem;
  line-height: 1.25;
  padding: 0.75rem;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.field::placeholder {
  color: var(--text-3);
}

.field:focus,
.field:focus-visible {
  position: relative;
  z-index: 1;
  outline: none;
  border-color: var(--accent-color);
  box-shadow: var(--focus-ring);
}

.field.error {
  border-color: color-mix(in srgb, var(--danger) 60%, transparent);
  background-color: var(--danger-soft);
}

/* ---------------------------------------------------------------------------
   Forms: a card of labelled fields, with the main action at the bottom right
   --------------------------------------------------------------------------- */
.formCard {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  padding: 1.25rem 1.5rem 1.5rem;
  border-radius: var(--radius-lg);
  background-color: var(--surface);
  box-shadow: var(--shadow-sm);
}

.formField {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  min-width: 0;
}

/* A label with something on its right, such as a character counter. */
.labelRow {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 1rem;
}

.fieldLabel {
  font-size: var(--text-footnote);
  font-weight: 600;
  color: var(--text-2);
}

.fieldMessage {
  font-size: var(--text-footnote);
  line-height: 1.35;
  color: var(--text-2);
}

.fieldMessage.error {
  color: var(--danger);
}

.fieldMessage.success {
  color: var(--success);
}

.fieldMessage:empty {
  display: none;
}

.formFooter {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: flex-end;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

/* A text field with a fixed prefix (a moon's "/") and room for a status icon
   at its end. It looks and focuses like .field. */
.prefixField {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 0 0.75rem;
  border: 1px solid var(--separator-strong);
  border-radius: var(--radius-md);
  background-color: var(--bg-1);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.prefixField:focus-within {
  border-color: var(--accent-color);
  box-shadow: var(--focus-ring);
}

.prefixField.error {
  border-color: color-mix(in srgb, var(--danger) 60%, transparent);
  background-color: var(--danger-soft);
}

.prefixField > .prefix {
  flex-shrink: 0;
  margin-right: 0.15rem;
  color: var(--text-3);
  user-select: none;
}

.prefixField > input {
  flex: 1;
  min-width: 0;
  height: 2.75rem;
  padding: 0;
  border: none;
  background: transparent;
  font-size: 1rem;
}

.prefixField > input:focus,
.prefixField > input:focus-visible {
  outline: none;
}

.prefixField > input::placeholder {
  color: var(--text-3);
}

@media (max-width: 600px) {
  .formCard {
    padding: 1rem 1rem 1.25rem;
  }
}

/* ---------------------------------------------------------------------------
   Shared buttons
   --------------------------------------------------------------------------- */

/* A quiet filled button: "See more replies", "Try again", "Cancel". */
.btn-secondary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  min-height: var(--control-sm);
  padding: 0 0.85rem;
  border: none;
  border-radius: var(--radius-md);
  background-color: var(--fill-secondary);
  color: var(--text-1);
  font-size: var(--text-subhead);
  font-weight: 500;
  line-height: 1.2;
  text-decoration: none;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

/* A transparent button that only shows a fill on hover: post actions, dismiss. */
.btn-ghost {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  min-height: var(--control-sm);
  padding: 0.3rem 0.5rem;
  border: none;
  border-radius: var(--radius-sm);
  background-color: transparent;
  text-decoration: none;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

/* A round ghost button holding a single icon. */
.btn-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--control-md);
  height: var(--control-md);
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background-color: transparent;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .btn-secondary:hover:not(:disabled) {
    background-color: var(--fill-secondary-hover);
  }

  .btn-ghost:hover:not(:disabled),
  .btn-icon:hover:not(:disabled) {
    background-color: var(--fill-hover);
  }
}

.btn-ghost:active:not(:disabled),
.btn-icon:active:not(:disabled) {
  background-color: var(--fill-pressed);
}

.btn-secondary:active:not(:disabled),
.btn-ghost:active:not(:disabled),
.btn-icon:active:not(:disabled) {
  transform: scale(0.97);
}

.btn-secondary:disabled,
.btn-ghost:disabled,
.btn-icon:disabled {
  cursor: default;
  opacity: 0.5;
}

/* Bigger targets for fingers (the control heights also grow). */
@media (pointer: coarse) {
  .btn-ghost {
    min-width: 2.5rem;
  }
}

/* Visually hidden, still read by screen readers. */
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
  border: 0;
}

/* ---------------------------------------------------------------------------
   Layout
   --------------------------------------------------------------------------- */
#app {
  display: flex;
}

/* Pages are up to 40rem wide and shrink to fit between the gutters. */
.page-content {
  /* Pages can centre things in the visible area (e.g. the post loader). */
  position: relative;
  flex: 1;
  display: flex;
  justify-content: center;
  padding: 0 1rem;
  overflow-y: scroll;
}

/* Below the fixed top bar on small screens. */
.page-content.compact {
  margin-top: var(--top-bar-height);
}

/* Pages other than full-width and centred ones start this far down. */
.page-content > .pagePadded {
  padding-top: 5rem;
}

/* The top bar already takes up some of the space above. */
.page-content.compact > .pagePadded {
  padding-top: 1.5rem;
}

.page-enter-active {
  transition: opacity var(--duration-base) var(--ease-out);
}

.page-leave-active {
  transition: opacity 120ms var(--ease-in-out);
}

.page-enter-from,
.page-leave-to {
  opacity: 0;
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

.error-banner-enter-active {
  transition:
    opacity var(--duration-base) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}

.error-banner-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-in-out),
    transform var(--duration-fast) var(--ease-in-out);
}

.error-banner-enter-from,
.error-banner-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* A safety net: with reduced motion, transitions finish at once (rather than
   being skipped, so end states and transitionend still happen). Loading
   indicators keep their own, gentler, animations. */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    transition-duration: 1ms !important;
    transition-delay: 0ms !important;
    scroll-behavior: auto !important;
  }
}
</style>
