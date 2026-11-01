<script lang="ts">
import { defineComponent, provide, reactive, watch } from 'vue'
import { routeLocationKey, useRoute, type RouteLocationNormalizedLoaded } from 'vue-router'

// Gives the page inside it its own route: it follows query changes on the
// page's own path, and stops once the route moves to another path. Pages fade
// out after the route has already changed, and without this a leaving page
// would react to the next page's route (e.g. a post page fetching
// `/post/undefined` on its way out). `useRoute()` inside reads this one.
export default defineComponent({
  name: 'PageRouteScope',
  setup(_props, { slots }) {
    const route = useRoute()
    const ownPath = route.path
    const pageRoute = reactive({ ...route }) as RouteLocationNormalizedLoaded

    watch(
      () => route.fullPath,
      () => {
        if (route.path === ownPath) {
          Object.assign(pageRoute, route)
        }
      },
    )

    provide(routeLocationKey, pageRoute)

    // The page's own element, not a fragment, so <Transition> can animate it.
    return () => slots.default?.()[0]
  },
})
</script>
