<template>
  <div>
    <h1>Create post</h1>
    <SegmentedControl :segments="['Text', 'Image']" style="margin-top: 20px;" />

    <div>
      <input placeholder="Moon" ref="moon" @input="clearError('moon')" />
      <p class="error">{{ this.errors.moon }}</p>
    </div>

    <div style="margin-top: 30px;">
      <div>
        <textarea
          name="title"
          placeholder="Title"
          class="title"
          ref="title"
          @input="onInput, clearError('form')"
          @keypress="onKeypress($event)"
          rows="1"
        />
      </div>
      <div style="margin-top: 15px;">
        <textarea
          name="text"
          placeholder="Text"
          class="text"
          ref="text"
          @input="clearError('form')"
        />
        <p class="error">{{ this.errors.form }}</p>
      </div>
    </div>

    <Button style="float: right; margin: 30px 0px;" width="91px" @click="createPost">
      <Loader v-if="loading" :size="30" bgColor="transparent" fgColor="#fff" />
      <span v-else>Create</span>
    </Button>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import Button from "@/components/Button.vue";
import Loader from "@/components/Loader.vue";
import axios from "axios";

@Options({
  components: {
    SegmentedControl,
    Button,
    Loader,
  },
})
export default class CreateMoon extends Vue {
  loading = false;
  errors = {
    moon: "",
    form: "",
  };

  onInput(): void {
    const title = <HTMLTextAreaElement>this.$refs.title;
    title.style.height = "auto";
    title.style.height = title.scrollHeight - 20 + "px";
  }

  onKeypress(event: KeyboardEvent): void {
    if (event.key == "Enter") {
      event.preventDefault();
    }
  }

  clearError(field: string): void {
    (<Record<string, unknown>>this.errors)[field] = "";
  }

  async createPost(): Promise<void> {
    this.loading = true;

    const title = (<HTMLTextAreaElement>this.$refs.title).value;
    const text = (<HTMLTextAreaElement>this.$refs.text).value;
    const moon = (<HTMLInputElement>this.$refs.moon).value.toLowerCase();

    let isFormValid = true;
    if (!moon) {
      this.errors.moon = "Please fill this out";
      isFormValid = false;
    }
    if (!title || !text) {
      this.errors.form = "Please fill out all fields";
      isFormValid = false;
    }

    if (!isFormValid) {
      this.loading = false;
      return;
    }

    const res = await axios
      .get(`http://localhost:4000/moon/${moon}`, {
        withCredentials: true,
      })
      .catch((err) => {
        return err.response;
      });

    if (res.data == "Not found") {
      this.errors.moon = "This moon doesn't exist";
      this.loading = false;
      return;
    }

    axios
      .post(
        "http://localhost:4000/post",
        { title: title, body: text, moon_id: res.data.id },
        {
          withCredentials: true,
        }
      )
      .then(() => {
        this.loading = false;
        this.$router.push({ name: "Moon", params: { moon: moon } });
      })
      .catch((err) => {
        this.loading = false;
        console.log(err.response);
      });
  }
}
</script>

<style scoped>
h1 {
  margin-top: 30px;
}
.title {
  width: 520px;
  resize: none;
  overflow-y: hidden;
}
.text {
  width: 520px;
  height: 150px;
  min-height: 150px;
  resize: vertical;
}
textarea {
  font-size: 20px;
  outline: none;
  border: none;
  font-weight: normal;
  padding: 10px 15px 10px 15px;
  -webkit-appearance: none;
  background-color: white;
  color: black;
  border-radius: 15px;
  font-family: inherit;
}
textarea::placeholder {
  color: var(--textTertiary);
}

input {
  background-color: var(--backgroundSecondary);
  color: var(--textPrimary);
  font-size: 20px;
  padding: 10px 15px 10px 15px;
  border-radius: 15px;
  border: none;
  outline: none;
  width: 200px;
  display: flex;
  align-items: center;
  margin-top: 30px;
}

::placeholder {
  color: var(--textTertiary);
}

.error {
  color: red;
  margin-top: 5px;
}
</style>
