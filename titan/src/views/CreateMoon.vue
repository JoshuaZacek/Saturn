<template>
  <div>
    <h1>Create moon</h1>
    <div class="inputWrapper">
      <input
        type="text"
        name="name"
        placeholder="name"
        ref="moonName"
        spellcheck="false"
        @keydown.enter="createMoon"
        :class="{ error: error }"
        @input="validate"
      />
      <label for="name">/</label>
      <p>{{ error }}</p>
      <Tooltip class="tooltip"
        >Moon names can only contain letters, numbers and underscores. This name cannot be
        changed.</Tooltip
      >
    </div>
    <Button style="float: right;" @click="createMoon" width="91px">
      <Loader v-if="loading" :size="30" bgColor="transparent" fgColor="#fff" />
      <span v-else>Create</span>
    </Button>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";
import Tooltip from "@/components/Tooltip.vue";
import Loader from "@/components/Loader.vue";
import axios from "axios";

@Options({
  components: {
    Button,
    Tooltip,
    Loader,
  },
})
export default class CreateMoon extends Vue {
  loading = false;
  error = "";

  capitalize(string: string): string {
    return string.charAt(0).toUpperCase() + string.slice(1);
  }

  createMoon(): void {
    this.loading = true;

    const name = (<HTMLInputElement>this.$refs.moonName).value;
    if (!name) {
      this.error = "Please enter a name";
    }

    if (this.error) {
      this.loading = false;
      return;
    }

    axios
      .post(
        "http://localhost:4000/moon",
        { name: name },
        {
          withCredentials: true,
        }
      )
      .then(() => {
        this.loading = false;
        this.$router.push({ name: "Moon", params: { moon: name } });
      })
      .catch((err) => {
        this.loading = false;
        if (err?.response?.status == 400) {
          const errors = err.response.data.errors;
          const errorKeys = Object.keys(errors);

          for (let i = 0; i < errorKeys.length; i++) {
            const key = errorKeys[i];
            this.error = `${this.capitalize(key)} ${errors[key]}`;
          }
        } else {
          this.error = "Something went wrong, check console for details";
          throw err;
        }
      });
  }

  validate(): void {
    const name = (<HTMLInputElement>this.$refs.moonName).value;

    if (!/^\w+$/.test(name) && name) {
      this.error = "Moon names must only contain letters, numbers and underscores";
      this.loading = false;
    } else {
      this.error = "";
    }
  }
}
</script>

<style scoped>
h1 {
  margin-top: 30px;
}
.inputWrapper {
  position: relative;
  margin-top: 20px;
  margin-bottom: 30px;
}
input {
  width: 500px;
  outline: none;
  border: none;
  font-size: 35px;
  font-weight: bold;
  padding: 10px 50px 10px 30px;
  -webkit-appearance: none;
  background-color: white;
  color: black;
  border-radius: 15px;
  box-sizing: border-box;
}
input::placeholder {
  color: var(--textTertiary);
}
input.error {
  border-color: #ff0000;
  border-style: solid;
  border-width: 2px;
}
label {
  position: absolute;
  left: 15px;
  top: 10px;
  font-size: 35px;
  font-weight: bold;
  color: var(--textTertiary);
}
.tooltip {
  position: absolute;
  top: 20px;
  right: 20px;
}
p {
  color: red;
  margin-top: 10px;
}
</style>
