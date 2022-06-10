<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div class="container">
    <div class="profileImage"></div>

    <div class="commentCollaper"></div>

    <div class="content">
      <div class="details">
        <p>{{ comment.user.username }}</p>

        <p>{{ timeSince }}</p>
      </div>

      <p>{{ comment.content }}</p>

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

      <button class="replyButton" @click="replyToggled = !replyToggled">
        <img src="/reply.svg" height="15" />
        Reply
      </button>

      <div v-if="replyToggled && this.$store.getters.isLoggedIn" class="replyContainer">
        <textarea
          name="reply"
          ref="reply"
          :placeholder="`Reply as ${this.$store.getters.getUser.username}...`"
          class="reply"
          @input="adjustHeight"
          rows="1"
        />
        <button
          class="sendReply"
          @click="
            sendReply(this.$route.params.id, this.$refs.reply.value, this.comment.id)
          "
        >
          Send reply
        </button>
        <button class="cancel" @click="replyToggled = false">Cancel</button>
      </div>
      <div v-if="replyToggled && !this.$store.getters.isLoggedIn" class="replyContainer">
        <p>Log in to your account to send a reply.</p>
      </div>

      <Comment v-for="reply in replies" :key="reply.id" :comment="reply" />
    </div>
  </div>
</template>

<script lang="ts">
import Overlay from "@/components/Overlay.vue";
import { relativeTime } from "@/relativeTime";
import axios from "axios";
import { Options, Vue } from "vue-class-component";

@Options({
  props: {
    comment: Object,
  },
  components: {
    Overlay,
  },
})
export default class Post extends Vue {
  comment!: Record<string, unknown>;

  timeSince = "";
  replies = [];
  replyToggled = false;
  overlayMessage = "";
  overlayStatus = "";
  currentVote = "";

  async created(): Promise<void> {
    const replies = await axios
      .get(
        `http://localhost:4000/comments?post_id=${this.$route.params.id}&parent_comment_id=${this.comment.id}`,
        {
          withCredentials: true,
        }
      )
      .catch(() => {
        return { data: [] }; // return 0 comments
      });

    this.replies = replies.data;

    if (this.comment.hasVoted === 1) {
      this.currentVote = "up";
    } else if (this.comment.hasVoted === -1) {
      this.currentVote = "down";
    }

    this.timeSince = relativeTime(new Date(<string>this.comment.inserted_at));
  }

  adjustHeight(): void {
    const reply = <HTMLTextAreaElement>this.$refs.reply;
    reply.style.height = "auto";
    reply.style.height = reply.scrollHeight + 2 + "px";
  }

  sendReply(post_id: number, content: string, comment_id: number): void {
    this.overlayStatus = "load";
    this.overlayMessage = "Sending reply";

    axios
      .post(
        "http://localhost:4000/comment",
        {
          post_id: post_id,
          comment_id: comment_id,
          content: content,
        },
        { withCredentials: true }
      )
      .then((res) => {
        (<Record<string, unknown>[]>this.replies).push(res.data);
        this.replyToggled = false;

        this.overlayStatus = "success";
        this.overlayMessage = "Reply sent";

        setTimeout(() => {
          this.overlayStatus = "";
        }, 1000);
      });
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
  position: relative;
  margin-top: 10px;
  margin-left: 5px;
}
.content {
  padding: 0px 0px 0px 10px;
  margin-top: 15px;
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

.details {
  font-size: 14px;
  margin-bottom: 2px;
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

.replyButton {
  padding: 5px 10px;
  border: none;
  border-radius: 12px;
  cursor: pointer;

  font-size: 15px;
  font-weight: normal;
  margin-top: 2px;
  margin-left: -5px;

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

.replyContainer {
  position: relative;
  width: 300px;
}
.replyContainer > p {
  color: var(--textTertiary);
  margin-top: 5px;
}

.reply {
  color: var(--textPrimary);
  font-size: 16px;
  font-family: inherit;

  outline: none;
  border: 1px solid var(--backgroundTertiary);

  margin-top: 10px;
  padding: 10px 15px 35px 15px;
  box-sizing: border-box;
  border-radius: 15px;
  width: 100%;
  resize: none;
  overflow-y: hidden;
}
.reply::placeholder {
  color: var(--textTertiary);
}
.reply:focus {
  border-color: var(--textTertiary);
}

.sendReply {
  position: absolute;
  bottom: 6px;
  right: 3px;
  padding: 5px 10px;

  border: none;
  border-radius: 12px;
  cursor: pointer;

  font-weight: 500;
  font-size: 15px;

  background-color: transparent;
  color: #006cff;
}
.sendReply:hover {
  background-color: #006cff11;
}

.cancel {
  position: absolute;
  bottom: 6px;
  right: 98px;
  padding: 5px 10px;

  border: none;
  border-radius: 12px;
  cursor: pointer;

  font-size: 15px;
  background-color: transparent;
  color: #ff0000;
}
.cancel:hover {
  background-color: #ff000011;
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
</style>
