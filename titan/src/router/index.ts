import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router'
import Home from '../views/Home.vue'
import Moon from '../views/Moon.vue'
import NotFound from '../views/404.vue'
import CreateMoon from '../views/CreateMoon.vue'
import CreatePost from '../views/CreatePost.vue'
import Settings from '../views/Settings.vue'
import PostWithComments from '../views/PostWithComments.vue'

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/404',
    name: '404',
    component: NotFound
  },
  {
    path: '/settings',
    name: 'Settings',
    component: Settings
  },
  {
    path: '/create/moon',
    name: 'CreateMoon',
    component: CreateMoon
  },
  {
    path: '/create/post',
    name: 'CreatePost',
    component: CreatePost
  },
  {
    path: '/post/:id/:comment?',
    name: "PostWithComments",
    component: PostWithComments
  },
  {
    path: '/:moon',
    name: "Moon",
    component: Moon,
  },
  // {
  //   path: '/about',
  //   name: 'About',
  //   // route level code-splitting
  //   // this generates a separate chunk (about.[hash].js) for this route
  //   // which is lazy-loaded when the route is visited.
  //   component: () => import(/* webpackChunkName: "about" */ '../views/About.vue')
  // }
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
})

export default router
