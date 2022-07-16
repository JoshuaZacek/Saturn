<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <Modal @close="$emit('close')">
    <h2>Change password</h2>
    <p>Your new password must contain 8 characters or more</p>

    <form ref="form" @submit.prevent="changePassword" novalidate>
      <Input
        label="Old password"
        type="password"
        :error="errors.oldPass"
        @input="errors.oldPass = ''"
      />
      <Input
        label="New password"
        type="password"
        :error="errors.newPass"
        @input="errors.newPass = ''"
      />

      <Button>Change password</Button>
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
export default class ChangePassword extends Vue {
  errors = {
    oldPass: "",
    newPass: "",
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

  validate(oldPass: string, newPass: string): boolean {
    let valid = true;

    if (oldPass == newPass) {
      this.errors.newPass = "Your new password cannot be the same";
      valid = false;
    }
    if (newPass.length < 8) {
      this.errors.newPass = "Your new password must contain 8 characters or more";
      valid = false;
    }
    if (!oldPass) {
      this.errors.oldPass = "Enter your old password";
      valid = false;
    }
    if (!newPass) {
      this.errors.newPass = "Enter your new password";
      valid = false;
    }

    return valid;
  }

  changePassword(): void {
    const formData = new FormData(<HTMLFormElement>this.$refs.form);
    const oldPass = <string>formData.get("oldpassword");
    const newPass = <string>formData.get("newpassword");

    this.errors = {
      oldPass: "",
      newPass: "",
    };
    if (!this.validate(oldPass, newPass)) return;

    this.setOverlay("load", "Changing password", false);

    axios
      .post(`${process.env.VUE_APP_API_URL}user/password`, formData, {
        withCredentials: true,
      })
      .then(async () => {
        await this.setOverlay("success", "Password changed");
        this.$emit("close");
      })
      .catch((err) => {
        if (err?.response?.status == 400) {
          this.setOverlay("", "", false);

          const errors = err.response.data.errors;
          console.log(errors);

          if (errors.password) this.errors.oldPass = errors.password[0];
        } else {
          this.setOverlay("error", "Couldn't change password");
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
