<template>
  <div style="width: 550px;">
    <h1>Settings</h1>

    <div class="settingContainer">
      <span>
        <p class="settingTitle">Email</p>
        <p class="settingDescription">{{ this.$store.getters.getUser.email }}</p>
      </span>

      <button>Change</button>
    </div>

    <div class="settingContainer">
      <span>
        <p class="settingTitle">Password</p>
      </span>

      <button @click="modalOpen('changePassword')">Change</button>
    </div>

    <div class="divider"></div>

    <div class="settingContainer" style="margin-top: 20px;">
      <span>
        <p class="settingTitle">Delete account</p>
        <p class="settingDescription">
          Your posts, comments, moons and profile will be deleted
        </p>
      </span>
      <button class="destructive">Delete</button>
    </div>
  </div>

  <Modal
    title="Change password"
    v-if="modal == 'changePassword'"
    @close="modalClose"
    @buttonClick="changePassword"
  >
    <template #message>Your new password should be at least 8 characters long</template>
    <template #content>
      <form @submit.prevent="changePassword" novalidate>
        <Input
          label="Old password"
          name="oldPassword"
          type="password"
          :error="errors.oldPassword"
          @input="eraseErrors"
        />
        <Input
          label="New password"
          name="newPassword"
          type="password"
          :error="errors.newPassword"
          @input="eraseErrors"
        />
        <!-- this hidden submit button is needed for the form to submit when the enter key is pressed -->
        <input type="submit" style="visibility: hidden; position: absolute;" />
      </form>
    </template>
    <template #primaryButton>
      <Loader v-if="processingRequest" :size="30" bgColor="transparent" fgColor="#fff" />
      <span v-else>Change password</span>
    </template>
  </Modal>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Modal from "@/components/Modal.vue";
import Input from "@/components/Input.vue";
import Loader from "@/components/Loader.vue";
import axios from "axios";

@Options({
  components: {
    Input,
    Loader,
    Modal,
  },
})
export default class Settings extends Vue {
  modal = "";
  errors: Record<string, string> = {
    oldPassword: "",
    newPassword: "",
  };
  processingRequest = false;

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
  eraseErrors(e: InputEvent): void {
    let name = (<HTMLInputElement>e.target).name;

    if (this.errors[name]) {
      this.errors[name] = "";
    }
  }

  //change password
  changePassword(): void {
    this.processingRequest = true;
    const oldPassword = (<HTMLInputElement>document.getElementsByName("oldPassword")[0])
      .value;
    const newPassword = (<HTMLInputElement>document.getElementsByName("newPassword")[0])
      .value;

    axios
      .post(
        "http://localhost:4000/account/password",
        { oldPassword, newPassword },
        { withCredentials: true }
      )
      .then(() => {
        this.processingRequest = false;
        this.modalClose();
      })
      .catch((err) => {
        console.log(err?.response);
        this.processingRequest = false;
        if (err?.response?.status == 400) {
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
  }
}
</script>

<style scoped>
h1 {
  margin-top: 30px;
}
.settingContainer {
  display: flex;
  justify-content: space-between;
  margin-top: 20px;
}
button {
  border: none;
  cursor: pointer;
  font-weight: 600;
  font-size: 16px;
  color: #006cff;
  background: none;
  position: relative;
}
button:before {
  content: "";
  width: 2px;
  height: 10px;
  background-color: #006cff;
  position: absolute;
  right: -10px;
  margin-top: 1px;
  border-radius: 1px;
  transform: rotate(-45deg);
}
button:after {
  content: "";
  width: 2px;
  height: 10px;
  background-color: #006cff;
  position: absolute;
  right: -10px;
  margin-top: 7px;
  border-radius: 1px;
  transform: rotate(45deg);
}
button.destructive {
  color: red;
}
button.destructive:before {
  background-color: red;
}
button.destructive:after {
  background-color: red;
}
.settingTitle {
  margin-bottom: 2px;
  font-weight: bold;
}
.settingDescription {
  color: var(--textSecondary);
}
form > div {
  margin-top: 20px;
}
.divider {
  margin-top: 20px;
  width: 450px;
  height: 1px;
  background: var(--backgroundTertiary);
}
</style>
