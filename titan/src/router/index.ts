import { createRouter, createWebHistory, type RouteLocationNormalizedLoaded } from 'vue-router'
import AllPage from '@/views/AllPage.vue'
import MoonPage from '@/views/MoonPage.vue'
import NotFoundPage from '@/views/NotFoundPage.vue'
import PostPage from '@/views/PostPage.vue'
import HomePage from '@/views/HomePage.vue'
import ProfilePage from '@/views/ProfilePage.vue'
import CreatePostPage from '@/views/CreatePostPage.vue'
import CreateMoonPage from '@/views/CreateMoonPage.vue'

export const isCorrectTimePeriod = (value: unknown) => {
  if (typeof value !== 'string') {
    return false
  }

  const validTimePeriods = ['day', 'week', 'month', 'year', 'all']

  return validTimePeriods.includes(value)
}

const DEFAULT_DOCUMENT_TITLE = 'Saturn'

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

        return { name: 'not-found' }
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
      },
    },
    {
      path: '/create/moon',
      name: 'create-moon',
      component: CreateMoonPage,
      meta: {
        title: 'Create moon',
      },
    },
    {
      path: '/:moon',
      name: 'moon',
      component: MoonPage,
      meta: {
        title: (to: RouteLocationNormalizedLoaded) => `/${String(to.params.moon)}`,
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
      path: '/post/:post_id',
      name: 'post',
      component: PostPage,
      meta: {
        title: (to: RouteLocationNormalizedLoaded) => `Saturn`,
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
