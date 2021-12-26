<template>
  <!-- NAVBAR -->
  <div class="navbar">
    <router-link :to="{ name: 'Home' }">Saturn</router-link>
    <span v-if="!this.$store.getters.isLoggedIn">
      <Button style="margin-right: 10px" @click="modalOpen('login')">Log in</Button>
      <Button buttonType="secondary" @click="modalOpen('signup')">Sign up</Button>
    </span>
    <UserMenu
      :username="this.$store.getters.getUser.username"
      :options="['Settings', 'Profile', 'Create post', 'Create moon', 'Log out']"
      v-else
    />
  </div>

  <!-- AUTHENTICATION MODALS -->
  <!-- LOGIN -->
  <Modal title="Log in" v-if="modal == 'login'" @close="modalClose" @buttonClick="login">
    <template #message>Login to your Saturn account</template>
    <template #content>
      <form ref="loginForm" @submit.prevent="login" novalidate>
        <Input
          label="Email"
          name="email"
          type="email"
          :error="errors.email"
          @input="eraseErrors"
        />
        <Input
          label="Password"
          name="password"
          type="password"
          :error="errors.password"
          @input="eraseErrors"
        />
        <!-- this hidden submit button is needed for the form to submit when the enter key is pressed -->
        <input type="submit" style="visibility: hidden; position: absolute;" />
      </form>
    </template>
    <template #primaryButton>
      <Loader v-if="sendingForm" :size="30" bgColor="transparent" fgColor="#fff" />
      <span v-else>Log in</span>
    </template>
    <template #footer>
      Don't have an account?
      <span
        tabindex="0"
        class="link"
        @keydown.space="modalOpen('signup')"
        @keydown.enter="modalOpen('signup')"
        @click="modalOpen('signup')"
        >Sign up</span
      >
    </template>
  </Modal>

  <!-- SIGN UP -->
  <Modal
    title="Sign up"
    v-else-if="modal == 'signup'"
    @close="modalClose"
    @buttonClick="signup"
  >
    <template #message>Sign up to create a Saturn account</template>
    <template #content>
      <form ref="signupForm" @submit.prevent="signup" novalidate>
        <Input
          label="Email"
          name="email"
          type="email"
          :error="errors.email"
          @input="eraseErrors"
        />
        <Input
          label="Username"
          name="username"
          type="text"
          :error="errors.username"
          @input="eraseErrors"
        />
        <Input
          label="Password"
          name="password"
          type="password"
          :error="errors.password"
          @input="eraseErrors"
        />
        <!-- this hidden submit button is needed for the form to submit when the enter key is pressed -->
        <input type="submit" style="visibility: hidden; position: absolute;" />
      </form>
    </template>
    <template #primaryButton>
      <Loader v-if="sendingForm" :size="30" bgColor="transparent" fgColor="#fff" />
      <span v-else>Sign up</span>
    </template>
    <template #footer>
      Have an account?
      <span
        tabindex="0"
        class="link"
        @keydown.space="modalOpen('login')"
        @keydown.enter="modalOpen('login')"
        @click="modalOpen('login')"
        >Log in</span
      >
    </template>
  </Modal>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";
import Modal from "@/components/Modal.vue";
import Input from "@/components/Input.vue";
import Loader from "@/components/Loader.vue";
import UserMenu from "@/components/UserMenu.vue";
import axios from "axios";

@Options({
  name: "Navbar",
  components: {
    Button,
    Modal,
    Input,
    Loader,
    UserMenu,
  },
})
export default class Navbar extends Vue {
  // typescript stuff
  modal = "";
  sendingForm = false;
  errors: Record<string, string> = {
    email: "",
    password: "",
    username: "",
  };
  declare $refs: {
    loginForm: HTMLFormElement;
    signupForm: HTMLFormElement;
  };

  // modal visibiliy/switching code
  modalOpen(modal: string): void {
    const exisingErrorKeys = Object.keys(this.errors);
    for (let i = 0; i < exisingErrorKeys.length; i++) {
      let key = exisingErrorKeys[i];
      this.errors[key] = "";
    }
    this.modal = modal;
  }
  modalClose(): void {
    const exisingErrorKeys = Object.keys(this.errors);
    for (let i = 0; i < exisingErrorKeys.length; i++) {
      let key = exisingErrorKeys[i];
      this.errors[key] = "";
    }
    this.modal = "";
  }

  // authentication code
  eraseErrors(e: InputEvent): void {
    let name = (<HTMLInputElement>e.target).name;

    if (this.errors[name]) {
      this.errors[name] = "";
    }
  }
  login(): void {
    this.sendingForm = true;

    // the setTimeout is used so that the user *always* sees the loading spinner
    setTimeout(() => {
      const email = (<HTMLInputElement>document.getElementsByName("email")[0]).value;
      const password = (<HTMLInputElement>document.getElementsByName("password")[0])
        .value;

      let isFormValid = true;
      if (!email) {
        this.errors.email = "Please enter an email";
        isFormValid = false;
      }
      if (!password) {
        this.errors.password = "Please enter a password";
        isFormValid = false;
      }

      if (!isFormValid) {
        this.sendingForm = false;
        return;
      }

      const formData = new FormData(this.$refs.loginForm);
      axios
        .post("http://localhost:4000/login", formData, {
          withCredentials: true,
        })
        .then((res) => {
          console.log(res);
          this.$store.dispatch("login", res.data);
          this.sendingForm = false;
          this.modalClose();
          this.$router.go(0);
        })
        .catch((err) => {
          this.sendingForm = false;
          if (err?.response?.status == 401) {
            const errors = err.response.data.errors;
            const errorKeys = Object.keys(errors);

            for (let i = 0; i < errorKeys.length; i++) {
              const key = errorKeys[i];
              this.errors[key] = errors[key][0];
            }
          } else {
            this.errors.password = "Something went wrong, check console for details.";
            throw err;
          }
        });
    }, 100);
  }
  signup(): void {
    this.sendingForm = true;

    // the setTimeout is used so that the user *always* sees the loading spinner
    setTimeout(() => {
      // client side validation
      const username = (<HTMLInputElement>document.getElementsByName("username")[0])
        .value;
      const email = (<HTMLInputElement>document.getElementsByName("email")[0]).value;
      const password = (<HTMLInputElement>document.getElementsByName("password")[0])
        .value;

      let isFormValid = true;
      if (!email) {
        this.errors.email = "Please enter an email";
        isFormValid = false;
      }
      if (!password) {
        this.errors.password = "Please enter a password";
        isFormValid = false;
      }
      if (!username) {
        this.errors.username = "Please enter a username";
        isFormValid = false;
      }

      if (!isFormValid) {
        this.sendingForm = false;
        return;
      }

      const formData = new FormData(this.$refs.signupForm);
      axios
        .post("http://localhost:4000/signup", formData, {
          withCredentials: true,
        })
        .then((res) => {
          console.log(res);
          this.$store.dispatch("login", res.data);
          this.sendingForm = false;
          this.modalClose();
          this.$router.go(0);
        })
        .catch((err) => {
          this.sendingForm = false;
          if (err?.response?.status == 401) {
            const errors = err.response.data.errors;
            const errorKeys = Object.keys(errors);

            for (let i = 0; i < errorKeys.length; i++) {
              const key = errorKeys[i];
              this.errors[key] = errors[key][0];
            }
          } else {
            this.errors.password = "Something went wrong, check console for details.";
            throw err;
          }
        });
    }, 100);
  }
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

form > div {
  margin-top: 20px;
}
.link {
  color: #006cff;
  text-decoration: none;
  font-weight: 600;
  font-size: inherit;
  cursor: pointer;
}
</style>
