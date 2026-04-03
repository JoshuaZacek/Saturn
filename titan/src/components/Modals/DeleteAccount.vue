<template>
<Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <Modal :easyCloseMode="false">
    <h2>Are you sure you want to delete your account?</h2>
    <p>Your account will be permanently deleted, and you won't be able to recover it.</p>

    <p>Once you delete your account, your:
      <ul>
        <li>Posts</li>
        <li>Comments</li>
        <li>Moons</li>
        <li>and Votes</li>
      </ul>
    will also be permanently deleted.</p>

    <p>Deleting your account will take effect immediately.</p>

    <div class="buttonContainer">
      <Button @click="$emit('close')" size="small">No, take me back</Button>
      <Button @click="deleteAccount" size="small" color="red">Yes, delete my account</Button>
    </div>
  </Modal>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Modal from "@/components/Modal.vue";
import Button from "@/components/Button.vue";
import Overlay from "@/components/Overlay.vue";
import axios from "axios";

@Options({
  components: {
    Modal,
    Button,
    Overlay
  },
  emits: ["close"],
})
export default class DeleteAccount extends Vue {
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

  deleteAccount(): void {
    this.setOverlay("load", "Deleting account", false);

    axios.delete(`${process.env.VUE_APP_API_URL}/user`, { withCredentials: true })
    .then(async () => {
      this.$store.dispatch("logout");
      await this.setOverlay("success", "Account deleted");
      this.$router.push({ name: "Home"});
    })
    .catch(() => {
      this.setOverlay("error", "Account couldn't be deleted")
    })
  }
}
</script>

<style scoped>
ul {
  list-style-position: inside;
  margin: 5px 10px;
}
p {
  margin-top: 10px;
}
.buttonContainer {
  float: right;
  margin-top: 10px;
}
</style>