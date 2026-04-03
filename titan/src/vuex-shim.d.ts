import { Store } from 'vuex'

declare module '@vue/runtime-core' {
  // Declare your own store states.
  interface State {
    loggedIn: boolean
    user: Record<string, unknown>
  }

  interface ComponentCustomProperties {
    $store: Store<State>
  }
}