<template>
  <div class="container">
    <p class="commentHeader">
      Commented on
      <span
        class="postTitle"
        @click="
          $router.push({ name: 'PostWithComments', params: { id: comment.post.id } })
        "
        >{{ comment.post.title }}</span
      >
    </p>

    <div class="comment">
      <div class="profileImage"></div>

      <div class="commentCollaper"></div>

      <div class="details">
        <p>{{ comment.user.username }}</p>

        <p>{{ timeSince }}</p>
      </div>

      <p>{{ comment.content }}</p>
    </div>

    <div class="voteButtons">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
        <path
          d="M659.21,143.52c-82.32-141.36-218.55-141.36-295.78,0L72,653.61c-80.86,140.64-14.57,255,145.71,255H804.92c162.46,0,228.76-114.4,145.7-255Z"
          style="fill:none;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
          :class="[currentVote == 'up' ? 'up' : '', 'vote']"
          @click="submitVote('up')"
        />
      </svg>

      <p>{{ comment.votes }}</p>

      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
        <path
          d="M364.79,802.63C447.11,944,583.34,944,660.57,802.63L952,292.54c80.86-140.64,14.57-255-145.71-255H219.08c-162.46,0-228.76,114.41-145.7,255Z"
          style="fill:none;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
          :class="[currentVote == 'down' ? 'down' : '', 'vote']"
          @click="submitVote('down')"
        />
      </svg>
    </div>

    <button
      class="replyButton"
      @click="
        $router.push({
          name: 'PostWithComments',
          params: { id: comment.post.id, comment: comment.id },
        })
      "
    >
      <img src="/comment.svg" height="15" />
      See replies
    </button>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import { relativeTime } from "@/relativeTime";
import axios from "axios";

@Options({
  props: {
    comment: Object,
  },
})
export default class CommentProfile extends Vue {
  comment!: Record<string, unknown>;
  timeSince = "";
  currentVote = "";

  created(): void {
    if (this.comment.hasVoted === 1) {
      this.currentVote = "up";
    } else if (this.comment.hasVoted === -1) {
      this.currentVote = "down";
    }

    this.timeSince = relativeTime(new Date(<string>this.comment.inserted_at));
  }

  deleteVote(): void {
    axios
      .delete(`http://localhost:4000/vote?comment_id=${this.comment.id}`, {
        withCredentials: true,
      })
      .then(() => {
        if (this.currentVote == "up") {
          (<number>this.comment.votes) -= 1;
        } else if (this.currentVote == "down") {
          (<number>this.comment.votes) += 1;
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
        `http://localhost:4000/vote?vote=${vote}&comment_id=${this.comment.id}`,
        {},
        {
          withCredentials: true,
        }
      )
      .then(() => {
        if (vote == "up") {
          if (this.currentVote == "down") {
            (<number>this.comment.votes) += 2;
          } else {
            (<number>this.comment.votes) += 1;
          }

          this.currentVote = "up";
        } else if (vote == "down") {
          if (this.currentVote == "up") {
            (<number>this.comment.votes) -= 2;
          } else {
            (<number>this.comment.votes) -= 1;
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
.container {
  width: 550px;
  background-color: var(--backgroundSecondary);
  padding: 15px 20px 10px;
  border-radius: 15px;
  margin-bottom: 20px;
  box-sizing: border-box;
}
.comment {
  position: relative;
  padding: 0px 0px 0px 10px;
  margin: 10px 0px 10px 10px;
}

.profileImage {
  width: 15px;
  height: 15px;
  position: absolute;
  background-color: var(--backgroundTertiary);
  border-radius: 50%;
  left: -11.5px;
}
.commentCollaper {
  width: 2px;
  background-color: var(--backgroundTertiary);
  height: calc(100% - 20px);
  position: absolute;
  left: -5px;
  top: 20px;
  border-radius: 1px;
}
.commentHeader {
  font-size: 14px;
  color: var(--textSecondary);
}
.postTitle {
  color: var(--textPrimary);
  font-weight: bold;
}
.postTitle:hover {
  text-decoration: underline;
  cursor: pointer;
}

.details {
  font-size: 14px;
  margin-bottom: 1px;
}
.details > * {
  display: inline-block;
}
.details > *:not(:last-child):after {
  content: "//";
  color: var(--textSecondary);
  margin: 0px 7px;
  display: inline-block;
  font-weight: normal;
}
.details > p {
  color: var(--textSecondary);
}
.details > p:first-child {
  color: var(--textPrimary);
  font-weight: bold;
}

.voteButtons {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  margin-right: 15px;
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

.replyButton {
  padding: 5px 10px;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  margin-top: -5px;
  margin-left: -5px;

  font-size: 15px;
  font-weight: normal;

  background-color: transparent;
  color: var(--textPrimary);

  display: inline-flex;
  justify-content: center;
  align-items: center;
}
.replyButton:hover {
  background-color: var(--backgroundTertiary);
}
.replyButton > img {
  margin-right: 5px;
}
</style>
