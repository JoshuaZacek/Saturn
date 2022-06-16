<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div v-if="fetchingInitialContent">
    <Loader :size="40" bgColor="#fcfcfc" fgColor="#d9d9d9" />
    <p>Loading post...</p>
  </div>

  <div class="postContainer" v-else>
    <h3>{{ post.title }}</h3>

    <div class="details">
      <a @click="$router.push({ name: 'Moon', params: { moon: post.moon.name } })">
        <strong>/{{ post.moon.name }}</strong>
      </a>

      <p>{{ post.user.username }}</p>

      <p>{{ timeSince }}</p>
    </div>

    <p class="postBody" v-if="!this.$route.params.comment">{{ post.body }}</p>

    <div class="voteButtons">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
        <path
          d="M659.21,143.52c-82.32-141.36-218.55-141.36-295.78,0L72,653.61c-80.86,140.64-14.57,255,145.71,255H804.92c162.46,0,228.76-114.4,145.7-255Z"
          style="fill:none;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
          :class="[currentVote == 'up' ? 'up' : '', 'vote']"
          @click="submitVote('up')"
        />
      </svg>

      <p>{{ post.votes }}</p>

      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
        <path
          d="M364.79,802.63C447.11,944,583.34,944,660.57,802.63L952,292.54c80.86-140.64,14.57-255-145.71-255H219.08c-162.46,0-228.76,114.41-145.7,255Z"
          style="fill:none;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
          :class="[currentVote == 'down' ? 'down' : '', 'vote']"
          @click="submitVote('down')"
        />
      </svg>
    </div>

    <div v-if="!this.$route.params.comment">
      <div class="commentContainer" v-if="this.$store.getters.isLoggedIn">
        <textarea
          name="comment"
          ref="comment"
          :placeholder="`Comment as ${this.$store.getters.getUser.username}...`"
          class="comment"
          @input="adjustHeight"
          rows="3"
        />
        <button
          class="postComment"
          @click="postComment(this.post.id, this.$refs.comment.value)"
        >
          Post comment
        </button>
      </div>

      <div class="commentContainer" v-else>
        <p>Log in to your account to post a comment.</p>
      </div>

      <h3>{{ post.comments }} comments</h3>
    </div>

    <button
      @click="
        $router.push({
          name: 'PostWithComments',
          params: { id: this.$route.params.id },
        })
      "
      v-else
    >
      See all comments on this post
    </button>

    <Comment
      v-for="comment in comments"
      :key="comment.id"
      :comment="comment"
      :level="0"
    />

    <div v-if="fetchingComments">
      <Loader :size="30" bgColor="#ffffff" fgColor="#d9d9d9" />
    </div>
  </div>
</template>

<script lang="ts">
// Packages
import { Options, Vue } from "vue-class-component";
import { relativeTime } from "@/relativeTime";
import axios from "axios";

// Components
import SegmentedControl from "@/components/SegmentedControl.vue";
import Button from "@/components/Button.vue";
import Loader from "@/components/Loader.vue";
import Comment from "@/components/Comment.vue";
import Overlay from "@/components/Overlay.vue";

@Options({
  components: {
    SegmentedControl,
    Button,
    Loader,
    Comment,
    Overlay,
  },
})
export default class FullPagePost extends Vue {
  // Define variables and types
  fetchingInitialContent = true;
  fetchingComments = true;
  overlayMessage = "";
  overlayStatus = "";
  currentVote = "";
  timeSince = "";
  nextCursor: string | null = null;

  post!: Record<string, unknown>;
  comments!: Record<string, unknown>[];

  // Lifecycle hooks
  async created(): Promise<void> {
    const post = await axios.get(`http://localhost:4000/post/${this.$route.params.id}`, {
      withCredentials: true,
    });

    if (this.$route.params.comment) {
      const comments = await axios.get(
        `http://localhost:4000/comments/${this.$route.params.comment}`,
        {
          withCredentials: true,
        }
      );

      this.comments = [comments.data];
    } else {
      const comments = await axios.get(
        `http://localhost:4000/comments?post_id=${this.$route.params.id}&limit=5`,
        {
          withCredentials: true,
        }
      );

      this.comments = comments.data.comments;
      this.nextCursor = comments.data.next_cursor;
    }

    this.post = post.data;

    this.timeSince = relativeTime(new Date(<string>this.post.inserted_at));

    if (this.post.hasVoted === 1) {
      this.currentVote = "up";
    } else if (this.post.hasVoted === -1) {
      this.currentVote = "down";
    }

    this.fetchingInitialContent = false;
    this.fetchingComments = false;

    window.onscroll = () => {
      if (window.innerHeight + window.pageYOffset >= document.body.offsetHeight - 2) {
        if (this.nextCursor && !this.fetchingComments) {
          this.fetchingComments = true;

          axios
            .get(
              `http://localhost:4000/comments?post_id=${this.$route.params.id}&limit=10&cursor=${this.nextCursor}`,
              {
                withCredentials: true,
              }
            )
            .then((res) => {
              setTimeout(() => {
                this.comments = this.comments.concat(
                  <Record<string, unknown>[]>res.data.comments
                );
                this.nextCursor = <string | null>res.data.next_cursor;
                this.fetchingComments = false;
              }, 500);
            });
        }
      }
    };
  }

  adjustHeight(): void {
    const comment = <HTMLTextAreaElement>this.$refs.comment;
    comment.style.height = "auto";
    comment.style.height = comment.scrollHeight + 2 + "px";
  }

  // API
  postComment(post_id: number, content: string): void {
    this.overlayStatus = "load";
    this.overlayMessage = "Posting comment";

    axios
      .post(
        "http://localhost:4000/comment",
        {
          post_id: post_id,
          content: content,
        },
        { withCredentials: true }
      )
      .then((res) => {
        res.data.votes = 0;
        this.comments.unshift(res.data);
        (<number>this.post.comments) += 1;

        this.overlayStatus = "success";
        this.overlayMessage = "Comment posted";

        setTimeout(() => {
          this.overlayStatus = "";
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
  width: 700px;
  background-color: var(--backgroundSecondary);
  padding: 15px 20px;
  border-radius: 15px;
  margin-bottom: 20px;
  box-sizing: border-box;
  margin-top: 30px;
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

.postBody {
  margin: 10px 0px 0px 0px;
}

.voteButtons {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  margin-top: 15px;
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

.commentContainer {
  position: relative;
  width: 100%;
  margin: 20px 0px;
}
.commentContainer > p {
  color: var(--textTertiary);
}

.comment {
  color: var(--textPrimary);
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
.comment:focus {
  border-color: var(--textTertiary);
}

button {
  padding: 5px 10px;
  display: block;
  margin-top: 10px;
  margin-left: -10px;

  border: none;
  border-radius: 12px;
  cursor: pointer;

  font-weight: 500;
  font-size: 15px;

  background-color: transparent;
  color: #006cff;
}
button:hover {
  background-color: #006cff11;
}

.postComment {
  position: absolute;
  bottom: 6px;
  right: 3px;
}
</style>
