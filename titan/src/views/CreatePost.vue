<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div>
    <h1>Create post</h1>
    <SegmentedControl
      :segments="postTypes"
      @change="changePostType"
      class="segmentedControl"
    />

    <MoonSearch class="moonSearch" @click="errors.moon = ''" @select="changeMoon" />
    <p v-if="this.errors.moon">{{ this.errors.moon }}</p>

    <textarea
      placeholder="Title"
      class="title"
      ref="title"
      @input="
        changeInputHeight();
        errors.form = '';
      "
      @keypress.enter.prevent
      rows="1"
    />
    <textarea
      v-if="currentPostType == 'Text'"
      placeholder="Text"
      class="text"
      ref="text"
      @input="errors.form = ''"
    />
    <input v-if="currentPostType == 'Image'" type="file" ref="file" accept="image/*" />

    <p v-if="this.errors.form">{{ this.errors.form }}</p>

    <Button class="createButton" @click="createPost">Create</Button>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import Button from "@/components/Button.vue";
import Loader from "@/components/Loader.vue";
import MoonSearch from "@/components/MoonSearch.vue";
import Overlay from "@/components/Overlay.vue";
import axios from "axios";

@Options({
  components: {
    SegmentedControl,
    Button,
    Loader,
    MoonSearch,
    Overlay,
  },
})
export default class CreateMoon extends Vue {
  errors = {
    moon: "",
    form: "",
  };
  currentMoon: Record<string, unknown> = {};
  overlayStatus = "";
  overlayMessage = "";
  postTypes = ["Text", "Image"];
  currentPostType = this.postTypes[0];
  declare $refs: {
    title: HTMLTextAreaElement;
    text: HTMLTextAreaElement;
    file: HTMLInputElement;
  };

  created(): void {
    if (!this.$store.getters.isLoggedIn) {
      this.$router.replace({ name: "404" });
    }
  }

  changePostType(postType: string): void {
    this.errors = {
      moon: "",
      form: "",
    };
    this.currentPostType = postType;
  }

  changeMoon(moon: Record<string, unknown>): void {
    this.currentMoon = moon;
  }

  changeInputHeight(): void {
    const title = this.$refs.title;
    title.style.height = "auto";
    title.style.height = title.scrollHeight - 20 + "px";
  }

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  validatePost(
    moon: Record<string, unknown>,
    title: string,
    text: string,
    fileList: FileList
  ): boolean {
    let valid = true;

    if (!moon.id) {
      this.errors.moon = "Please choose a moon";
      valid = false;
    }
    if (!fileList?.length && this.currentPostType == "Image") {
      this.errors.form = "Please upload an image";
      valid = false;
    }
    if (!title) {
      this.errors.form = "Please fill in all fields";
      valid = false;
    }
    if (!text && this.currentPostType == "Text") {
      this.errors.form = "Please fill in all fields";
      valid = false;
    }

    return valid;
  }

  async createPost(): Promise<void> {
    const moon = this.currentMoon;
    const title = this.$refs.title.value;
    const text = this.$refs.text?.value;
    const fileList = <FileList>this.$refs?.file?.files;

    this.errors = {
      moon: "",
      form: "",
    };
    if (!this.validatePost(moon, title, text, fileList)) {
      return;
    }

    this.setOverlay("load", "Creating post", false);

    const formData = new FormData();
    formData.append("moon_id", <string>this.currentMoon.id);
    formData.append("title", title);
    formData.append("body", text);
    formData.append("type", this.currentPostType.toLowerCase());
    if (this.currentPostType == "Image") {
      formData.append("file", fileList[0]);
    }

    axios
      .post("http://localhost:4000/post", formData, {
        withCredentials: true,
      })
      .then(async (res) => {
        await this.setOverlay("success", "Created post");

        this.$router.push({ name: "PostWithComments", params: { id: res.data.id } });
      })
      .catch(() => {
        this.setOverlay("error", "Couldn't create post");
      });
  }
}
</script>

<style scoped>
h1 {
  margin-top: 30px;
}

.segmentedControl {
  margin-top: 20px;
}

.moonSearch {
  margin-top: 30px;
}
.title {
  margin-top: 30px;
  width: 520px;

  resize: none;
  overflow-y: hidden;
}
.text {
  margin-top: 15px;
  width: 520px;

  height: 150px;
  min-height: 150px;

  resize: vertical;
}

textarea {
  background-color: white;
  color: black;

  font-size: 20px;
  font-family: inherit;
  font-weight: normal;

  padding: 10px 15px 10px 15px;
  display: block;

  outline: none;
  border: none;
  border-radius: 15px;
}
textarea::placeholder {
  color: var(--textTertiary);
}

input {
  margin-top: 15px;
}

.createButton {
  float: right;
  margin-top: 30px;
}

p {
  color: red;
  margin-top: 5px;
}
</style>
