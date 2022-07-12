<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <Modal @close="$emit('close')">
    <h2>Log in</h2>
    <p class="message">
      Already have an account?
      <Button size="small" @click="$emit('loginInstead')">Log in instead</Button>
    </p>

    <form ref="form" @submit.prevent="submitDetails" novalidate>
      <Input
        label="Email"
        type="email"
        :error="errors.email"
        @input="errors.email = ''"
      />
      <Input
        label="Username"
        type="text"
        :error="errors.username"
        @input="errors.username = ''"
      />
      <Input
        label="Password"
        type="password"
        :error="errors.password"
        @input="errors.password = ''"
      />

      <Button class="signupButton">Sign up</Button>
    </form>
  </Modal>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";
import Input from "@/components/Input.vue";
import Overlay from "@/components/Overlay.vue";
import Modal from "@/components/Modal.vue";
import axios from "axios";

@Options({
  name: "Signup",
  emits: ["close", "loginInstead"],
  components: {
    Button,
    Input,
    Overlay,
    Modal,
  },
})
export default class Signup extends Vue {
  errors: Record<string, unknown> = {
    email: "",
    username: "",
    password: "",
  };
  overlayMessage = "";
  overlayStatus = "";

  validateDetails(email: string, username: string, password: string): boolean {
    let valid = true;

    if (!email) {
      this.errors.email = "Please enter an email";
      valid = false;
    }

    if (!username) {
      this.errors.username = "Please enter a username";
      valid = false;
    }

    if (!password) {
      this.errors.password = "Please enter a password";
      valid = false;
    }

    return valid;
  }

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  submitDetails(): void {
    const formData = new FormData(<HTMLFormElement>this.$refs.form);
    const email = <string>formData.get("email");
    const username = <string>formData.get("username");
    const password = <string>formData.get("password");

    this.errors = {
      email: "",
      username: "",
      password: "",
    };

    if (!this.validateDetails(email, username, password)) {
      return;
    }

    this.setOverlay("load", "Signing up", false);

    axios
      .post("http://localhost:4000/signup", formData, { withCredentials: true })
      .then(async (res) => {
        this.$store.dispatch("login", res.data);
        await this.setOverlay("success", "Signed up");
        this.$router.go(0);
      })
      .catch((err) => {
        if (err?.response?.status == 401) {
          this.setOverlay("", "", false);

          const errors = err.response.data.errors;

          Object.keys(errors).forEach((key) => {
            this.errors[key] = errors[key][0];
          });
        } else {
          this.setOverlay("error", "Couldn't sign up");
        }
      });
  }
}
</script>

<style scoped>
.background {
  background-color: rgba(0, 0, 0, 0.75);
  position: fixed;
  z-index: 100;

  top: 0;
  bottom: 0;
  left: 0;
  right: 0;

  display: flex;
  justify-content: center;
  align-items: center;
}

.signup {
  width: 350px;
  padding: 15px 20px 20px;
  border-radius: 20px;
  background: var(--backgroundSecondary);
  position: relative;
}

.close {
  position: absolute;
  top: 15px;
  right: 15px;

  width: 25px;
  height: 25px;

  border: none;
  border-radius: 100%;
  cursor: pointer;

  background-color: #006cff11;
}
.close:before {
  content: "";
  width: 2px;
  height: 15px;
  background-color: #006cff;
  position: absolute;
  top: 5px;
  left: 11.5px;
  border-radius: 1px;
  transform: rotate(-45deg);
}
.close:after {
  content: "";
  width: 2px;
  height: 15px;
  background-color: #006cff;
  position: absolute;
  top: 5px;
  left: 11.5px;
  border-radius: 1px;
  transform: rotate(45deg);
}

.message {
  color: var(--textSecondary);
}
.message > button {
  margin-left: -5px;
}

form {
  margin-top: 15px;
}
form > div:not(:last-of-type) {
  margin-bottom: 20px;
}

.signupButton {
  margin-top: 20px;
  float: right;
}
</style>
