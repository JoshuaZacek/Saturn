<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <Modal @close="$emit('close')">
    <h2>Log in</h2>
    <p class="message">
      Don't have an account?
      <Button size="small" @click="$emit('signupInstead')">Sign up instead</Button>
    </p>

    <form ref="form" @submit.prevent="submitCredentials" novalidate>
      <Input
        label="Email"
        type="email"
        :error="errors.email"
        @input="errors.email = ''"
      />
      <Input
        label="Password"
        type="password"
        :error="errors.password"
        @input="errors.password = ''"
      />

      <Button class="loginButton">Log in</Button>
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
  name: "Login",
  emits: ["close", "signupInstead"],
  components: {
    Button,
    Input,
    Overlay,
    Modal,
  },
})
export default class Login extends Vue {
  errors: Record<string, unknown> = {
    email: "",
    password: "",
  };
  overlayMessage = "";
  overlayStatus = "";

  validateCredentials(email: string, password: string): boolean {
    let valid = true;

    if (!email) {
      this.errors.email = "Please enter an email";
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

  submitCredentials(): void {
    const formData = new FormData(<HTMLFormElement>this.$refs.form);
    const email = <string>formData.get("email");
    const password = <string>formData.get("password");

    this.errors = {
      email: "",
      password: "",
    };

    if (!this.validateCredentials(email, password)) {
      return;
    }

    this.setOverlay("load", "Logging in", false);

    axios
      .post("http://localhost:4000/user/login", formData, { withCredentials: true })
      .then(async (res) => {
        this.$store.dispatch("login", res.data);
        await this.setOverlay("success", "Logged in");
        this.$router.go(0);
      })
      .catch((err) => {
        if (err?.response?.status == 400) {
          this.setOverlay("", "", false);

          const errors = err.response.data.errors;

          Object.keys(errors).forEach((key) => {
            this.errors[key] = errors[key][0];
          });
        } else {
          this.setOverlay("error", "Couldn't log in");
        }
      });
  }
}
</script>

<style scoped>
.message {
  color: var(--textSecondary);
}
.message > button {
  margin-left: -5px;
}

form {
  margin-top: 15px;
}
form > div:first-child {
  margin-bottom: 20px;
}

.loginButton {
  margin-top: 20px;
  float: right;
}
</style>
