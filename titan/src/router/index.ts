import {
  createRouter,
  createWebHistory,
  type RouteLocationNormalizedLoaded,
  type RouteLocationRaw,
} from 'vue-router'
import AllPage from '@/views/AllPage.vue'
import MoonPage from '@/views/MoonPage.vue'
import NotFoundPage from '@/views/NotFoundPage.vue'
import PostPage from '@/views/PostPage.vue'
import HomePage from '@/views/HomePage.vue'
import ProfilePage from '@/views/ProfilePage.vue'
import CreatePostPage from '@/views/CreatePostPage.vue'
import CreateMoonPage from '@/views/CreateMoonPage.vue'
import UnauthorizedPage from '@/views/UnauthorizedPage.vue'
import SettingsPage from '@/views/SettingsPage.vue'

export const isCorrectTimePeriod = (value: unknown) => {
  if (typeof value !== 'string') {
    return false
  }

  const validTimePeriods = ['day', 'week', 'month', 'year', 'all']

  return validTimePeriods.includes(value)
}

// Shows the Not Found page without changing the address bar, for pages that
// only find out their content is missing after a request (e.g. a 404 moon).
export const notFoundLocation = (route: RouteLocationNormalizedLoaded): RouteLocationRaw => ({
  name: 'not-found',
  params: { pathMatch: route.path.slice(1).split('/') },
  query: route.query,
  hash: route.hash,
})

const DEFAULT_DOCUMENT_TITLE = 'Saturn'
const AUTH_STORAGE_KEY = 'auth-user'

const isLoggedIn = () => {
  const storedUser = localStorage.getItem(AUTH_STORAGE_KEY)

  if (!storedUser) {
    return false
  }

  try {
    JSON.parse(storedUser)
    return true
  } catch {
    localStorage.removeItem(AUTH_STORAGE_KEY)
    return false
  }
}

const requireLogin = (to: RouteLocationNormalizedLoaded) => {
  if (isLoggedIn()) {
    return true
  }

  return {
    name: 'unauthorized',
    query: { message: to.meta.unauthorizedMessage as string | undefined },
  }
}

type RouteTitleResolver = (to: RouteLocationNormalizedLoaded) => string

const resolveDocumentTitle = (to: RouteLocationNormalizedLoaded) => {
  const titleMeta = to.meta.title as string | RouteTitleResolver | undefined

  if (typeof titleMeta === 'function') {
    return titleMeta(to)
  }

  if (typeof titleMeta === 'string' && titleMeta.trim().length > 0) {
    return titleMeta
  }

  return DEFAULT_DOCUMENT_TITLE
}

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomePage,
      meta: {
        title: 'Saturn',
      },
    },
    {
      path: '/all',
      name: 'all',
      component: AllPage,
      meta: {
        title: 'Saturn',
      },
      beforeEnter: (to) => {
        const sort = to.query.sort
        const t = to.query.t

        if (sort === 'new') {
          return true
        }

        if (sort === 'top' && isCorrectTimePeriod(t)) {
          return true
        }

        return { name: 'all', query: { ...to.query, sort: 'top', t: 'day' } }
      },
    },
    {
      path: '/@:username',
      name: 'profile',
      component: ProfilePage,
      meta: {
        title: (to: RouteLocationNormalizedLoaded) => `@${String(to.params.username)}`,
      },
    },
    {
      path: '/create/post',
      name: 'create-post',
      component: CreatePostPage,
      meta: {
        title: 'Create post',
        unauthorizedMessage: 'You must be logged in to create a post',
      },
      beforeEnter: requireLogin,
    },
    {
      // Each step (change email, change password, delete account) replaces the
      // settings content; leaving out the step shows the main settings page.
      path: '/settings/:step(email|password|delete)?',
      name: 'settings',
      component: SettingsPage,
      meta: {
        title: 'Settings',
        unauthorizedMessage: 'You must be logged in to view your settings',
      },
      beforeEnter: requireLogin,
    },
    {
      path: '/unauthorized',
      name: 'unauthorized',
      component: UnauthorizedPage,
      meta: {
        title: 'Unauthorized',
      },
    },
    {
      path: '/create/moon',
      name: 'create-moon',
      component: CreateMoonPage,
      meta: {
        title: 'Create moon',
        unauthorizedMessage: 'You must be logged in to create a moon',
      },
      beforeEnter: requireLogin,
    },
    {
      path: '/:moon',
      name: 'moon',
      component: MoonPage,
      meta: {
        title: (to: RouteLocationNormalizedLoaded) => `/${String(to.params.moon)}`,
        // The page draws its own full-width banner from the very top.
        fullWidth: true,
      },
      beforeEnter: (to) => {
        const sort = to.query.sort
        const t = to.query.t

        if (sort === 'new') {
          return true
        }

        if (sort === 'top' && isCorrectTimePeriod(t)) {
          return true
        }

        return {
          name: 'moon',
          params: to.params,
          query: {
            ...to.query,
            sort: 'top',
            t: 'day',
          },
        }
      },
    },
    {
      path: '/post/:post_id/:comment_id?',
      name: 'post',
      component: PostPage,
      meta: {
        title: 'Saturn',
      },
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: NotFoundPage,
      meta: {
        title: 'Not Found',
      },
    },
  ],
})

router.afterEach((to) => {
  document.title = resolveDocumentTitle(to)
})

export default router
