import { createStore } from 'vuex'
import createPersistedState from "vuex-persistedstate"

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
    CHANGE_EMAIL(state, newEmail) {
      (<Record<string, unknown>>state.user).email = newEmail
    },
  },
  actions: {
    login({ commit }, user) {
      commit("LOG_IN", user);
    },
    logout({ commit }) {
      commit("LOG_OUT");
    },
    changeEmail({ commit }, newEmail) {
      commit("CHANGE_EMAIL", newEmail);
    },
  },
  getters: {
    isLoggedIn: (state) => {
      return state.loggedIn;
    },
    getUser: (state) => {
      return state.user;
    }
  },
  plugins: [createPersistedState()],
})
