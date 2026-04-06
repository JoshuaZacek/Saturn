import { createRouter, createWebHistory } from 'vue-router'
import AllPage from '@/views/AllPage.vue'
import MoonPage from '@/views/MoonPage.vue'
import NotFoundPage from '@/views/NotFoundPage.vue'
import PostPage from '@/views/PostPage.vue'
import SubscribedPage from '@/views/SubscribedPage.vue'

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
