<template>
  <div class="navbar">
    <router-link :to="{ name: 'Home' }">Saturn</router-link>

    <span v-if="!$store.getters.isLoggedIn">
      <Button @click="modal = 'login'">Log in</Button>
      <Button @click="modal = 'signup'">Sign up</Button>
    </span>

    <UserMenu v-else :username="$store.getters.getUser.username" />
  </div>

  <Login v-if="modal == 'login'" @close="modal = ''" @signupInstead="modal = 'signup'" />
  <Signup v-if="modal == 'signup'" @close="modal = ''" @loginInstead="modal = 'login'" />
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";
import Login from "@/components/Modals/Login.vue";
import Signup from "@/components/Modals/Signup.vue";
import UserMenu from "@/components/UserMenu.vue";

@Options({
  name: "Navbar",
  components: {
    Button,
    Login,
    Signup,
    UserMenu,
  },
})
export default class Navbar extends Vue {
  modal = "";
}
</script>

<style scoped>
.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;

  box-sizing: border-box;
  padding: 0 15px;
  width: 100%;
  height: 50px;

  position: sticky;
  top: 0px;
  z-index: 10;

  background: var(--backgroundSecondary);
}

a {
  font-weight: bold;
  font-size: 19px;
  text-decoration: none;
  color: var(--textPrimary);
}

span {
  display: flex;
  gap: 10px;
}
</style>
