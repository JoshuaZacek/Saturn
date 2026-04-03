<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div class="container">
    <h1>Create moon</h1>
    <p class="info">
      Moons can only contain letters, numbers and underscores. Moon names cannot be
      changed.
    </p>

    <div class="inputContainer">
      <input
        type="text"
        name="moon"
        placeholder="moon"
        ref="moon"
        spellcheck="false"
        :class="{ error: error }"
        @keydown.enter="createMoon"
        @input="validateMoon($refs.moon.value, true)"
      />
      <label for="moon">/</label>
      <p class="error">{{ error }}</p>
    </div>

    <Button class="createButton" @click="createMoon">Create</Button>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Overlay from "@/components/Overlay.vue";
import Button from "@/components/Button.vue";
import axios from "axios";

@Options({
  components: {
    Overlay,
    Button,
  },
})
export default class CreateMoon extends Vue {
  overlayMessage = "";
  overlayStatus = "";
  error = "";

  created(): void {
    if (!this.$store.getters.isLoggedIn) {
      this.$router.replace({ name: "404" });
    }
  }

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  validateMoon(name: string, live = false): boolean {
    let valid = true;

    if (!name) {
      this.error = "Please enter a moon";
      valid = false;
    }

    if (!/^\w+$/.test(name) && name) {
      this.error = "Moons can only contain letters, numbers and underscores";
      valid = false;
    } else if (live) {
      this.error = "";
    }

    return valid;
  }

  createMoon(): void {
    const moon = (<HTMLInputElement>this.$refs.moon).value;

    this.error = "";
    if (!this.validateMoon(moon)) {
      return;
    }

    this.setOverlay("load", "Creating moon", false);

    axios
      .post(
        `${process.env.VUE_APP_API_URL}/moon`,
        { name: moon },
        { withCredentials: true }
      )
      .then(async () => {
        await this.setOverlay("success", "Created moon");

        this.$router.push({ name: "Moon", params: { moon: moon } });
      })
      .catch((err) => {
        if (err?.response?.status == 400) {
          this.setOverlay("", "", false);

          const errors = err.response.data.errors;

          Object.keys(errors).forEach((key) => {
            this.error = this.error.concat(errors[key][0], "\n");
          });
        } else {
          this.setOverlay("error", "Couldn't create moon");
        }
      });
  }
}
</script>

<style scoped>
h1 {
  margin-top: 30px;
}
.info {
  max-width: 500px;
  color: var(--textSecondary);
  margin-top: 5px;
}

.inputContainer {
  position: relative;
  width: 100%;
  margin-top: 20px;
}
input {
  width: 100%;
  padding: 10px 50px 10px 30px;

  outline: none;
  border: none;
  border-radius: 15px;
  box-sizing: border-box;

  font-size: 35px;
  font-weight: bold;

  background-color: var(--backgroundSecondary);
  color: var(--textPrimary);
}
input::placeholder {
  color: var(--textTertiary);
}
label {
  position: absolute;
  left: 15px;
  top: 10px;
  font-size: 35px;
  font-weight: bold;
  color: var(--textTertiary);
}

p.error {
  color: red;
  margin-top: 10px;
}
input.error {
  background-color: #ff000011;
  color: #ff0000;
}
input.error::placeholder {
  color: #ff000050;
}
input.error + label {
  color: #ff000050;
}

.createButton {
  float: right;
  margin-top: 20px;
}

.container {
  width: 500px;
}

@media screen and (max-width: 540px) {
  .container {
    width: calc(100% - 40px);
  }
}
</style>
