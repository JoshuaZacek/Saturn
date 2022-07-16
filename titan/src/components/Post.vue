<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div class="postContainer">
    <h3>{{ post.title }}</h3>

    <div class="details">
      <a @click="$router.push({ name: 'Moon', params: { moon: post.moon.name } })">
        /{{ post.moon.name }}
      </a>

      <p
        class="username"
        @click="
          $router.push({ name: 'Profile', params: { username: post.user.username } })
        "
      >
        @{{ post.user.username }}
      </p>

      <p>{{ timeSince }}</p>
    </div>

    <img v-if="post.type == 'image'" :src="imageURL" :alt="post.body" class="postImage" />
    <p class="postBody" v-else>{{ post.body }}</p>

    <VoteButtons :content="post" type="post" />

    <button
      class="toolbarButton"
      @click="$router.push({ name: 'PostWithComments', params: { id: this.post.id } })"
    >
      <img src="/comment.svg" height="15" />
      {{ post.comments }}
    </button>

    <button
      class="toolbarButton"
      @click="deletePost"
      v-if="post.user.id == this.$store.getters.getUser.id"
    >
      <img src="/trash.svg" height="15" />
      Delete
    </button>
  </div>
</template>

<script lang="ts">
// Packages
import { Options, Vue } from "vue-class-component";
import Overlay from "@/components/Overlay.vue";
import VoteButtons from "@/components/VoteButtons.vue";
import axios from "axios";
import { relativeTime } from "@/relativeTime";

@Options({
  components: {
    Overlay,
    VoteButtons,
  },
  props: {
    post: Object,
  },
  emits: ["delete"],
})
export default class Post extends Vue {
  overlayMessage = "";
  overlayStatus = "";

  post!: Record<string, unknown>;

  get timeSince(): string {
    return relativeTime(new Date(<string>this.post.inserted_at));
  }

  get imageURL(): string {
    return `${process.env.VUE_APP_API_URL}assets/${this.post.body}`;
  }

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  deletePost(): void {
    this.setOverlay("load", "Deleting post", false);

    axios
      .delete(`${process.env.VUE_APP_API_URL}post/${this.post.id}`, {
        withCredentials: true,
      })
      .then(async () => {
        await this.setOverlay("success", "Post deleted");
        this.$emit("delete");
      })
      .catch(() => {
        this.setOverlay("error", "Post couldn't be deleted");
      });
  }
}
</script>

<style scoped>
.postContainer {
  width: 550px;
  background-color: var(--backgroundSecondary);
  padding: 15px 20px 10px;
  border-radius: 15px;
  margin-bottom: 20px;
  box-sizing: border-box;
  position: relative;
}

.postImage {
  width: calc(100% + 40px);
  margin: 15px 0px 10px 0px;
  left: -20px;
  position: relative;
}

.details {
  font-size: 14px;
  margin-top: 1px;
}
.details > * {
  display: inline-block;
}
.details > *:not(:last-child):after {
  content: "//";
  color: var(--textSecondary);
  margin: 0px 7px;
  display: inline-block;
}
.details > p {
  color: var(--textSecondary);
}
.details > a:hover {
  text-decoration: underline;
  cursor: pointer;
}
.username:hover {
  text-decoration: underline;
  cursor: pointer;
}

.postBody {
  margin: 10px 0px 15px 0px;
}

.toolbarButton {
  padding: 5px 10px;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  margin-top: -5px;

  font-size: 15px;
  font-weight: normal;

  background-color: transparent;
  color: var(--textPrimary);

  display: inline-flex;
  justify-content: center;
  align-items: center;
}

.toolbarButton:active {
  background-color: var(--backgroundTertiary);
}
@media (hover: hover) {
  .toolbarButton:hover {
    background-color: var(--backgroundTertiary);
  }
}
.toolbarButton > img {
  margin-right: 5px;
}

@media screen and (max-width: 590px) {
  .postContainer {
    width: calc(100% - 40px);
  }
}
</style>
