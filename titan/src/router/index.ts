import { createRouter, createWebHistory } from 'vue-router'
import AllPage from '@/views/AllPage.vue'
import MoonPage from '@/views/MoonPage.vue'
import NotFoundPage from '@/views/NotFoundPage.vue'
import PostPage from '@/views/PostPage.vue'
import SubscribedPage from '@/views/SubscribedPage.vue'
import ProfilePage from '@/views/ProfilePage.vue'

export const isCorrectTimePeriod = (value: unknown) => {
  if (typeof value !== 'string') {
    return false
  }

  const validTimePeriods = ['day', 'week', 'month', 'year', 'all']

  return validTimePeriods.includes(value)
}

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'subscribed',
      component: SubscribedPage,
    },
    {
      path: '/all',
      name: 'all',
      component: AllPage,
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
    },
    {
      path: '/:moon',
      name: 'moon',
      component: MoonPage,
    },
    {
      path: '/post/:post_id',
      name: 'post',
      component: PostPage,
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: NotFoundPage,
    },
  ],
})

export default router
