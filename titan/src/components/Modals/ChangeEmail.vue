<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <Modal @close="$emit('close')">
    <h2>Change email</h2>

    <form ref="form" @submit.prevent="changePassword" novalidate>
      <Input
        label="New email"
        type="email"
        :error="errors.newEmail"
        @input="errors.newEmail = ''"
      />
      <Input
        label="Confirm email"
        type="email"
        :error="errors.confirmEmail"
        @input="errors.confirmEmail = ''"
      />

      <Button>Change email</Button>
    </form>
  </Modal>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Modal from "@/components/Modal.vue";
import Input from "@/components/Input.vue";
import Button from "@/components/Button.vue";
import Overlay from "@/components/Overlay.vue";
import axios from "axios";

@Options({
  components: {
    Modal,
    Input,
    Button,
    Overlay,
  },
  emits: ["close"],
})
export default class ChangeEmail extends Vue {
  errors = {
    newEmail: "",
    confirmEmail: "",
  };
  overlayMessage = "";
  overlayStatus = "";

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  validate(newEmail: string, confirmEmail: string): boolean {
    let valid = true;

    if (newEmail != confirmEmail) {
      this.errors.confirmEmail = "Your email does not match";
      valid = false;
    }
    if (!/.+@(?=[^@]+$).+\.(?=[^.]+$)/.test(newEmail)) {
      this.errors.newEmail = "This is not a valid email";
      valid = false;
    }
    if (!newEmail) {
      this.errors.newEmail = "Enter your new email";
      valid = false;
    }
    if (!confirmEmail) {
      this.errors.confirmEmail = "Confirm your new email";
      valid = false;
    }

    return valid;
  }

  changePassword(): void {
    const formData = new FormData(<HTMLFormElement>this.$refs.form);
    const newEmail = <string>formData.get("newemail");
    const confirmEmail = <string>formData.get("confirmemail");

    this.errors = {
      newEmail: "",
      confirmEmail: "",
    };
    if (!this.validate(newEmail, confirmEmail)) return;

    this.setOverlay("load", "Changing email", false);

    axios
      .post("http://localhost:4000/account/email", formData, { withCredentials: true })
      .then(async () => {
        this.$store.dispatch("changeEmail", newEmail);
        await this.setOverlay("success", "Email changed");
        this.$emit("close");
      })
      .catch((err) => {
        if (err?.response?.status == 400) {
          this.setOverlay("", "", false);

          const errors = err.response.data.errors;

          if (errors.email) this.errors.newEmail = errors.email[0];
        } else {
          this.setOverlay("error", "Couldn't change email");
        }
      });
  }
}
</script>

<style scoped>
p {
  color: var(--textSecondary);
  margin-top: 2px;
}

form {
  margin-top: 15px;
}
form > div:first-child {
  margin-bottom: 20px;
}

button {
  margin-top: 20px;
  float: right;
}
</style>
