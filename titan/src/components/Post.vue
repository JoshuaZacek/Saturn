<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div class="postContainer">
    <h3>{{ post.title }}</h3>

    <div class="details">
      <a @click="$router.push({ name: 'Moon', params: { moon: post.moon.name } })">
        <strong>/{{ post.moon.name }}</strong>
      </a>

      <p
        class="username"
        @click="
          $router.push({ name: 'Profile', params: { username: post.user.username } })
        "
      >
        {{ post.user.username }}
      </p>

      <p>{{ timeSince }}</p>
    </div>

    <p class="postBody">{{ post.body }}</p>

    <div class="voteButtons">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
        <path
          d="M659.21,143.52c-82.32-141.36-218.55-141.36-295.78,0L72,653.61c-80.86,140.64-14.57,255,145.71,255H804.92c162.46,0,228.76-114.4,145.7-255Z"
          style="fill:transparent;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
          :class="[currentVote == 'up' ? 'up' : '', 'vote']"
          @click="submitVote('up')"
        />
      </svg>

      <p>{{ post.votes }}</p>

      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
        <path
          d="M364.79,802.63C447.11,944,583.34,944,660.57,802.63L952,292.54c80.86-140.64,14.57-255-145.71-255H219.08c-162.46,0-228.76,114.41-145.7,255Z"
          style="fill:transparent;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
          :class="[currentVote == 'down' ? 'down' : '', 'vote']"
          @click="submitVote('down')"
        />
      </svg>
    </div>

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
import axios from "axios";
import { relativeTime } from "@/relativeTime";

@Options({
  components: {
    Overlay,
  },
  props: {
    post: Object,
  },
  emits: ["delete"],
})
export default class Post extends Vue {
  // Define variables and types
  currentVote = "";
  timeSince = "";
  overlayMessage = "";
  overlayStatus = "";

  post!: Record<string, unknown>;

  // Lifecycle hooks
  created(): void {
    this.timeSince = relativeTime(new Date(<string>this.post.inserted_at));

    if (this.post.hasVoted === 1) {
      this.currentVote = "up";
    } else if (this.post.hasVoted === -1) {
      this.currentVote = "down";
    }
  }

  // API
  deletePost(): void {
    this.overlayMessage = "Deleting post";
    this.overlayStatus = "load";

    axios
      .delete(`http://localhost:4000/post/${this.post.id}`, {
        withCredentials: true,
      })
      .then(() => {
        this.overlayMessage = "Post deleted";
        this.overlayStatus = "success";

        setTimeout(() => {
          this.overlayStatus = "";
          this.overlayMessage = "";

          this.$emit("delete");
        }, 1000);
      })
      .catch(() => {
        this.overlayStatus = "error";
        this.overlayMessage = "Post couldn't be deleted";

        setTimeout(() => {
          this.overlayStatus = "";
          this.overlayMessage = "";
        }, 1000);
      });
  }

  deleteVote(): void {
    axios
      .delete(`http://localhost:4000/vote?post_id=${this.post.id}`, {
        withCredentials: true,
      })
      .then(() => {
        if (this.currentVote == "up") {
          (<number>this.post.votes) -= 1;
        } else if (this.currentVote == "down") {
          (<number>this.post.votes) += 1;
        }

        this.currentVote = "";
      });
  }

  submitVote(vote: string): void {
    if (vote == this.currentVote) {
      this.deleteVote();
      return;
    }

    axios
      .post(
        `http://localhost:4000/vote?vote=${vote}&post_id=${this.post.id}`,
        {},
        {
          withCredentials: true,
        }
      )
      .then(() => {
        if (vote == "up") {
          if (this.currentVote == "down") {
            (<number>this.post.votes) += 2;
          } else {
            (<number>this.post.votes) += 1;
          }

          this.currentVote = "up";
        } else if (vote == "down") {
          if (this.currentVote == "up") {
            (<number>this.post.votes) -= 2;
          } else {
            (<number>this.post.votes) -= 1;
          }

          this.currentVote = "down";
        }
      })
      .catch((err) => {
        console.log(err);
      });
  }
}
</script>

<style scoped>
.postContainer {
  width: 550px;
  background-color: var(--backgroundSecondary);
  padding: 15px 20px;
  border-radius: 15px;
  margin-bottom: 20px;
  box-sizing: border-box;
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

.voteButtons {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  margin-right: 10px;
}
.voteButtons > p {
  font-size: 15px;
}

.vote:not(.down, .up):hover {
  fill: var(--textSecondary) !important;
}

.vote.down {
  stroke: red !important;
}
.vote.down:hover {
  fill: #ff0000 !important;
}

.vote.up {
  stroke: #006cff !important;
}
.vote.up:hover {
  fill: #006cff !important;
}
svg {
  height: 15px;
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
.toolbarButton:hover {
  background-color: var(--backgroundTertiary);
}
.toolbarButton > img {
  margin-right: 5px;
}
</style>
