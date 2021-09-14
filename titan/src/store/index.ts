import { createStore } from 'vuex'

export default createStore({
  state: {
    loggedIn: false,
    user: {}
  },
  mutations: {
    LOG_IN(state, user) {
      state.user = user
      state.loggedIn = true;
    },
    LOG_OUT(state) {
      state.user = {}
      state.loggedIn = false;
    },
  },
  actions: {
    login({ commit }, user) {
      commit("LOG_IN", user);
    },
    logout({ commit }) {
      commit("LOG_OUT");
    },
  },
  getters: {
    isLoggedIn: (state) => {
      return state.loggedIn;
    },
    getUser: (state) => {
      return state.user;
    }
  }
})
