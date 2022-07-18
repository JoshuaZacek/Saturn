<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div v-if="fetchingPost" class="loaderContainer post">
    <Loader v-if="!error" :size="40" bgColor="#fcfcfc" fgColor="#d9d9d9" />
    <p>{{ error || "Loading post" }}</p>
  </div>

  <div class="postContainer" v-else>
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
      @click="deletePost"
      v-if="post.user.id == this.$store.getters.getUser.id"
    >
      <img src="/trash.svg" height="15" />
      Delete
    </button>

    <Button
      v-if="this.$route.params.comment"
      @click="
        $router.push({ name: 'PostWithComments', params: { id: this.$route.params.id } })
      "
      size="small"
      class="paginationButton"
    >
      See all comments on this post
    </Button>

    <div v-else>
      <div class="commentContainer" v-if="this.$store.getters.isLoggedIn">
        <textarea
          @input="changeCommentBoxHeight"
          :placeholder="`Comment as ${this.$store.getters.getUser.username}...`"
          ref="comment"
          rows="3"
          class="comment"
        />
        <Button @click="postComment" size="small" class="postButton">Post comment</Button>
      </div>

      <div class="commentContainer" v-else>
        <p>Log in to your account to post a comment.</p>
      </div>

      <h3>{{ numberOfComments }} {{ numberOfComments == 1 ? "comment" : "comments" }}</h3>

      <div v-if="numberOfComments" class="sortDropdown">
        <p>Sort by:</p>
        <Menu :options="commentSorts" @select="changeSort" />
      </div>
    </div>

    <Comment
      v-for="comment in comments"
      :key="comment.id"
      :comment="comment"
      :level="0"
    />

    <div v-if="fetchingComments" class="loaderContainer comments">
      <Loader v-if="!error" :size="30" bgColor="#ffffff" fgColor="#d9d9d9" />
      <p>{{ error || "Loading comments" }}</p>
    </div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import Button from "@/components/Button.vue";
import Loader from "@/components/Loader.vue";
import Comment from "@/components/Comment.vue";
import Overlay from "@/components/Overlay.vue";
import VoteButtons from "@/components/VoteButtons.vue";
import Menu from "@/components/Menu.vue";
import { relativeTime } from "@/relativeTime";
import axios from "axios";
import { computed } from "vue";

@Options({
  components: {
    SegmentedControl,
    Button,
    Loader,
    Comment,
    Overlay,
    VoteButtons,
    Menu,
  },
  provide() {
    return {
      incrementComments: this.incrementComments,
      currentSort: computed(() => this.currentSort),
    };
  },
})
export default class PostWithComments extends Vue {
  message = "Hello, World!";
  fetchingPost = true;
  fetchingComments = true;
  commentSorts = ["New", "Top"];
  currentSort = this.commentSorts[0].toLowerCase();
  error = "";
  overlayMessage = "";
  overlayStatus = "";

  nextCursor: string | null = null;
  comments: Record<string, unknown>[] = [];
  post!: Record<string, unknown>;
  numberOfComments = 0;

  declare $refs: {
    comment: HTMLTextAreaElement;
  };

  get imageURL(): string {
    return `${process.env.VUE_APP_API_URL}/assets/${this.post.body}`;
  }

  incrementComments(): void {
    this.numberOfComments += 1;
  }

  changeSort(sort: string): void {
    this.comments = [];
    this.currentSort = sort.toLowerCase();
    this.getComments();
  }

  // Lifecycle hooks
  async created(): Promise<void> {
    await axios
      .get(`${process.env.VUE_APP_API_URL}/post/${this.$route.params.id}`, {
        withCredentials: true,
      })
      .then((res) => {
        this.post = res.data;
        this.numberOfComments = res.data.comments;
        this.fetchingPost = false;
      })
      .catch((err) => {
        if (err?.response?.status == 404) {
          this.$router.replace({ name: "404" });
        } else {
          this.error = "Post couldn't be loaded";
        }
      });

    await this.getComments();

    window.onscroll = () => {
      if (window.innerHeight + window.pageYOffset >= document.body.offsetHeight - 2) {
        if (this.nextCursor && !this.fetchingComments) {
          this.getComments();
        }
      }
    };
  }

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  get timeSince(): string {
    return relativeTime(new Date(<string>this.post.inserted_at));
  }

  changeCommentBoxHeight(): void {
    const comment = this.$refs.comment;
    comment.style.height = "auto";
    comment.style.height = comment.scrollHeight + 2 + "px";
  }

  async getComments(): Promise<void> {
    this.fetchingComments = true;

    axios
      .get(
        `${process.env.VUE_APP_API_URL}/comments${
          this.$route.params.comment
            ? `/${this.$route.params.comment}`
            : `?post_id=${this.$route.params.id}&limit=10${
                this.nextCursor ? `&cursor=${this.nextCursor}` : ""
              }&sort=${this.currentSort}`
        }`,
        {
          withCredentials: true,
        }
      )
      .then((res) => {
        if (this.$route.params.comment) {
          this.comments = [res.data];
        } else {
          this.comments = this.comments.concat(res.data.comments);
          this.nextCursor = res.data.next_cursor;
        }

        this.fetchingComments = false;
      })
      .catch(() => {
        this.error = "Comments couldn't be loaded";
      });
  }

  deletePost(): void {
    this.setOverlay("load", "Deleting post", false);

    axios
      .delete(`${process.env.VUE_APP_API_URL}/post/${this.post.id}`, {
        withCredentials: true,
      })
      .then(async () => {
        await this.setOverlay("success", "Post deleted");
        this.$router.push({ name: "Home" });
      })
      .catch(() => {
        this.setOverlay("error", "Post couldn't be deleted");
      });
  }

  postComment(): void {
    const content = this.$refs.comment.value;

    this.setOverlay("load", "Posting comment", false);

    axios
      .post(
        `${process.env.VUE_APP_API_URL}/comment`,
        {
          post_id: this.post.id,
          content: content,
        },
        { withCredentials: true }
      )
      .then((res) => {
        this.setOverlay("success", "Comment posted");

        res.data.votes = 0;
        this.comments.unshift(res.data);
        this.incrementComments();
      });
  }
}
</script>

<style scoped>
.postContainer {
  width: 700px;
  background-color: var(--backgroundSecondary);
  padding: 15px 20px;
  border-radius: 15px;
  box-sizing: border-box;
  margin: 30px 0;
}

@media screen and (max-width: 740px) {
  .postContainer {
    width: calc(100% - 40px);
  }
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
.postImage {
  width: calc(100% + 40px);
  margin: 15px 0px 10px 0px;
  left: -20px;
  position: relative;
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
@media (hover: hover) {
  .toolbarButton:hover {
    background-color: var(--backgroundTertiary);
  }
}
.toolbarButton > img {
  margin-right: 5px;
}

.sortDropdown {
  margin-top: 10px;
}
.sortDropdown > * {
  display: inline-block;
}
.sortDropdown > p {
  margin-right: 5px;
}

.commentContainer {
  position: relative;
  width: 100%;
  margin: 15px 0px;
  color: var(--textTertiary);
}
.comment {
  font-size: 16px;
  font-family: inherit;

  outline: none;
  border: 1px solid var(--backgroundTertiary);

  padding: 10px 15px 35px 15px;
  box-sizing: border-box;
  border-radius: 15px;
  width: 100%;
  resize: none;
  overflow-y: hidden;
}
.comment::placeholder {
  color: var(--textTertiary);
}

.postButton {
  font-size: 15px;
  position: absolute;
  bottom: 6px;
  right: 3px;
}

.loaderContainer {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  color: #d9d9d9;
}
.loaderContainer.post {
  position: absolute;
  top: calc(50% + 25px);
  transform: translateY(-50%);
}
.loaderContainer.comments {
  gap: 5px;
  margin-top: 10px;
}

.paginationButton {
  display: block;
  margin-top: 10px;
  margin-left: -10px;
}
</style>
