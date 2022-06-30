<template>
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

    <div
      class="toolbarButton"
      @click="$router.push({ name: 'PostWithComments', params: { id: this.post.id } })"
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1023.95 1024">
        <path
          d="M848.88,715.26C928.49,648,979.62,557,985.81,456l.64-.46-.63.33q.63-10.25.63-20.64C986.45,215.57,774,37.5,512,37.5S37.5,215.57,37.5,435.22,249.93,832.94,512,832.94c30.2,0,59.91-3.14,88.37-6.89h0C717.49,1001.8,927,987,945,985.65,937.2,976.93,844.39,882,848.88,715.27Z"
          style="fill:none;stroke:#757575;stroke-miterlimit:10;stroke-width:75px"
        />
      </svg>
      <p>{{ post.comments }}</p>
    </div>
  </div>
</template>

<script lang="ts">
// Packages
import { Options, Vue } from "vue-class-component";
import axios from "axios";
import { relativeTime } from "@/relativeTime";

@Options({
  props: {
    post: Object,
  },
})
export default class Post extends Vue {
  // Define variables and types
  currentVote = "";
  timeSince = "";

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
  display: inline-flex;
  align-items: center;
  margin-left: 15px;
  padding: 5px 5px;
  gap: 7px;
  border-radius: 5px;
  cursor: pointer;

  position: absolute;
  margin-top: -5px;
}
.toolbarButton > p {
  font-size: 15px;
}
.toolbarButton:hover {
  background-color: var(--backgroundTertiary);
}
.toolbarButton:active {
  background-color: var(--textTertiary);
}
</style>
