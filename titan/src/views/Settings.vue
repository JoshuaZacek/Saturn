<template>
  <div class="container">
    <h1>Settings</h1>

    <div class="option">
      <span>
        <p class="title">Email</p>
        <p class="description">{{ this.$store.getters.getUser.email }}</p>
      </span>

      <Button @click="currentModal = 'email'" size="small">Change</Button>
    </div>

    <div class="option">
      <span>
        <p class="title">Password</p>
      </span>

      <Button @click="currentModal = 'password'" size="small">Change</Button>
    </div>

    <div class="divider"></div>

    <div class="option">
      <span>
        <p class="title">Delete account</p>
        <p class="description">Your posts, comments, moons and votes will be deleted</p>
      </span>

      <Button @click="currentModal = 'delete'" size="small" color="red">Delete</Button>
    </div>
  </div>

  <ChangePassword v-if="currentModal == 'password'" @close="currentModal = ''" />
  <ChangeEmail v-if="currentModal == 'email'" @close="currentModal = ''" />
  <DeleteAccount v-if="currentModal == 'delete'" @close="currentModal = ''" />
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";
import Modal from "@/components/Modal.vue";
import ChangePassword from "@/components/Modals/ChangePassword.vue";
import ChangeEmail from "@/components/Modals/ChangeEmail.vue";
import DeleteAccount from "@/components/Modals/DeleteAccount.vue";

@Options({
  components: {
    Button,
    Modal,
    ChangePassword,
    ChangeEmail,
    DeleteAccount,
  },
})
export default class Settings extends Vue {
  currentModal = "";

  created(): void {
    if (!this.$store.getters.isLoggedIn) {
      this.$router.replace({ name: "404" });
    }
  }
}
</script>

<style scoped>
.container {
  width: 550px;
  margin-top: 30px;
}

.option {
  display: flex;
  justify-content: space-between;
  align-items: center;

  margin-top: 20px;
}

.option > button {
  position: relative;
  padding-right: 20px;
}
.option > button:before {
  content: "";
  width: 2px;
  height: 10px;

  position: absolute;
  right: 10px;
  margin-top: 1px;

  border-radius: 1px;
  transform: rotate(-45deg);
}
.option > button:after {
  content: "";
  width: 2px;
  height: 10px;

  position: absolute;
  right: 10px;
  margin-top: 7px;

  border-radius: 1px;
  transform: rotate(45deg);
}
.option > button.blue:before,
.option > button.blue:after {
  background-color: #006cff;
}
.option > button.red:before,
.option > button.red:after {
  background-color: red;
}

.title {
  margin-bottom: 2px;
  font-weight: bold;
}
.description {
  color: var(--textSecondary);
}
.divider {
  margin-top: 20px;
  width: 450px;
  height: 1px;
  background: var(--backgroundTertiary);
}
</style>
