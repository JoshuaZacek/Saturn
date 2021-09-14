<template>
  <div class="navbar">
    <router-link to="/">Saturn</router-link>
    <span v-if="!this.$store.getters.isLoggedIn">
      <Button style="margin-right: 10px" @click="modalOpen('login')">Log in</Button>
      <Button buttonType="secondary" @click="modalOpen('signup')">Sign up</Button>
    </span>
    <UserMenu
      :username="this.$store.getters.getUser.username"
      :options="['Settings', 'Profile', 'Log out']"
      v-else
    />
  </div>
  <Modal @close="modalClose" v-if="showModal">
    <!-- Modal title -->
    <h2 v-if="modal == 'login'">Log in</h2>
    <h2 v-else>Sign up</h2>

    <!-- Modal description -->
    <p v-if="modal == 'login'">
      Log in to your Saturn account to create posts, participate in discussions and join
      moons.
    </p>
    <p v-else>
      Create your Saturn account to create posts, participate in discussions and join
      moons.
    </p>

    <!-- Modal form -->
    <form v-if="modal == 'login'" ref="loginForm" novalidate @submit.prevent="login">
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
      <Button :inModal="true">
        <Loader v-if="sendingForm" :size="30" bgColor="transparent" fgColor="#fff" />
        <span v-else>Log in</span>
      </Button>
    </form>
    <form ref="signupForm" @submit.prevent="signup" novalidate v-else>
      <Input
        label="Username"
        name="username"
        type="text"
        :error="errors.username"
        @input="eraseErrors"
      />
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
      <Button :inModal="true">
        <Loader v-if="sendingForm" :size="30" bgColor="transparent" fgColor="#fff" />
        <span v-else>Sign Up</span>
      </Button>
    </form>

    <!-- Modal footer -->
    <h5 v-if="modal == 'login'">
      Don't have a Saturn account?
      <span
        tabindex="0"
        @keydown.space="modalOpen('signup')"
        @keydown.enter="modalOpen('signup')"
        @click="modalOpen('signup')"
        >Sign up</span
      >
    </h5>
    <h5 v-else>
      Already using Saturn?
      <span
        tabindex="0"
        @keydown.space="modalOpen('login')"
        @keydown.enter="modalOpen('login')"
        @click="modalOpen('login')"
        >Log in</span
      >
    </h5>
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
  showModal = false;
  modal = "login";
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

  eraseErrors(e: InputEvent): void {
    let name = (<HTMLInputElement>e.target).name;

    if (this.errors[name]) {
      this.errors[name] = "";
    }
  }

  modalOpen(modal: string): void {
    const exisingErrorKeys = Object.keys(this.errors);
    for (let i = 0; i < exisingErrorKeys.length; i++) {
      let key = exisingErrorKeys[i];
      this.errors[key] = "";
    }
    this.showModal = true;
    this.modal = modal;
  }

  modalClose(): void {
    const exisingErrorKeys = Object.keys(this.errors);
    for (let i = 0; i < exisingErrorKeys.length; i++) {
      let key = exisingErrorKeys[i];
      this.errors[key] = "";
    }
    this.showModal = false;
  }

  login(): void {
    this.sendingForm = true;

    // The setTimeout makes sure the user sees the loader, even for a split second, which improves UX
    setTimeout(() => {
      const email = (<HTMLInputElement>document.getElementsByName("email")[0]).value;
      const password = (<HTMLInputElement>document.getElementsByName("password")[0])
        .value;

      if (!email) {
        this.errors.email = "Please enter an email";
      }
      if (!password) {
        this.errors.password = "Please enter a password";
      }

      // Check for new/unresolved errors before sending
      const exisingErrorKeys = Object.keys(this.errors);
      for (let i = 0; i < exisingErrorKeys.length; i++) {
        let key = exisingErrorKeys[i];
        if (this.errors[key]) {
          this.sendingForm = false;
          return;
        }
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
        })
        .catch((err) => {
          this.sendingForm = false;
          if (err.response.status == 401) {
            const errors = err.response.data.errors;
            const errorKeys = Object.keys(errors);

            for (let i = 0; i < errorKeys.length; i++) {
              const key = errorKeys[i];
              this.errors[key] = errors[key][0];
            }
          } else {
            throw err;
          }
        });
    }, 100);
  }

  signup(): void {
    this.sendingForm = true;

    // The setTimeout makes sure the user sees the loader, even for a split second, which improves UX
    setTimeout(() => {
      const username = (<HTMLInputElement>document.getElementsByName("username")[0])
        .value;
      const email = (<HTMLInputElement>document.getElementsByName("email")[0]).value;
      const password = (<HTMLInputElement>document.getElementsByName("password")[0])
        .value;

      if (!email) {
        this.errors.email = "Please enter an email";
      }
      if (!password) {
        this.errors.password = "Please enter a password";
      }
      if (!username) {
        this.errors.username = "Please enter a username";
      }

      // Check for new/unresolved errors before sending
      const exisingErrorKeys = Object.keys(this.errors);
      for (let i = 0; i < exisingErrorKeys.length; i++) {
        let key = exisingErrorKeys[i];
        if (this.errors[key]) {
          this.sendingForm = false;
          return;
        }
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
        })
        .catch((err) => {
          this.sendingForm = false;
          if (err.response.status == 401) {
            const errors = err.response.data.errors;
            const errorKeys = Object.keys(errors);

            for (let i = 0; i < errorKeys.length; i++) {
              const key = errorKeys[i];
              this.errors[key] = errors[key][0];
            }
          } else {
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

p {
  margin-top: 5px;
  color: var(--textSecondary);
}

h5 {
  color: var(--textSecondary);
  font-weight: normal;
  font-size: 14px;
  margin-bottom: 5px;
  margin-top: 5px;
}
h5 > span {
  color: #006cff;
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
}

form > div {
  margin-top: 20px;
}
form > button {
  margin-top: 20px;
  margin-bottom: 5px;
}
</style>
