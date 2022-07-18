<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div class="container">
    <div class="profileImage"></div>

    <div class="commentCollaper"></div>

    <div class="content">
      <div class="details">
        <p
          @click="
            $router.push({ name: 'Profile', params: { username: comment.user.username } })
          "
        >
          @{{ comment.user.username }}
        </p>

        <p>{{ timeSince }}</p>
      </div>

      <p>{{ comment.content }}</p>

      <VoteButtons :content="comment" type="type" />

      <button class="toolbarButton" @click="replyToggled = !replyToggled">
        <img src="/reply.svg" height="15" />
        Reply
      </button>

      <div v-if="replyToggled && this.$store.getters.isLoggedIn" class="replyContainer">
        <textarea
          ref="reply"
          :placeholder="`Reply as ${this.$store.getters.getUser.username}...`"
          class="reply"
          @input="adjustHeight"
          rows="1"
        />

        <div class="replyButtons">
          <Button @click="replyToggled = false" size="small" color="red">Cancel</Button>
          <Button @click="sendReply" size="small">Post comment</Button>
        </div>
      </div>

      <div v-if="replyToggled && !this.$store.getters.isLoggedIn" class="replyContainer">
        <p>Log in to your account to send a reply.</p>
      </div>

      <Comment
        v-for="reply in replies"
        :key="reply.id"
        :comment="reply"
        :level="level + 1"
      />

      <Button
        v-if="level == 3 && comment.replies > 0"
        @click="seeChildren"
        size="small"
        class="paginationButton"
        >See more replies</Button
      >
    </div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";
import Overlay from "@/components/Overlay.vue";
import VoteButtons from "@/components/VoteButtons.vue";
import axios from "axios";
import { relativeTime } from "@/relativeTime";

@Options({
  props: {
    comment: Object,
    level: Number,
  },
  components: {
    Button,
    Overlay,
    VoteButtons,
  },
  inject: ["incrementComments", "currentSort"],
})
export default class Comment extends Vue {
  comment!: Record<string, unknown>;
  level!: number;
  currentSort!: string;
  incrementComments!: () => void;

  replies: Record<string, unknown>[] = [];
  replyToggled = false;
  overlayMessage = "";
  overlayStatus = "";

  declare $refs: {
    reply: HTMLTextAreaElement;
  };

  async created(): Promise<void> {
    if (this.level < 3) {
      axios.get(this.generateURL(), { withCredentials: true }).then((res) => {
        this.replies = res.data.comments;
      });
    }
  }

  get timeSince(): string {
    return relativeTime(new Date(<string>this.comment.inserted_at));
  }

  generateURL(): string {
    return `${process.env.VUE_APP_API_URL}/comments?post_id=${this.$route.params.id}&parent_comment_id=${this.comment.id}&limit=10&sort=${this.currentSort}`;
  }

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  seeChildren(): void {
    const comment_id = <number>this.comment.id;

    this.$router.push({
      name: "PostWithComments",
      params: { id: this.$route.params.id, comment: comment_id },
    });
  }

  adjustHeight(): void {
    const reply = <HTMLTextAreaElement>this.$refs.reply;
    reply.style.height = "auto";
    reply.style.height = reply.scrollHeight + 2 + "px";
  }

  sendReply(): void {
    this.setOverlay("load", "Sending reply", false);

    const data = {
      post_id: this.$route.params.id,
      comment_id: this.comment.id,
      content: this.$refs.reply.value,
    };

    axios
      .post(`${process.env.VUE_APP_API_URL}/comment`, data, { withCredentials: true })
      .then((res) => {
        res.data.votes = 0;
        this.replies.push(res.data);
        this.replyToggled = false;
        this.incrementComments();

        this.setOverlay("success", "Reply sent");
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
.details > p:first-child:hover {
  text-decoration: underline;
  cursor: pointer;
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

.replyButtons {
  position: absolute;
  bottom: 6px;
  right: 3px;
}
.replyButtons > button {
  font-size: 15px;
}

.toolbarButton {
  padding: 5px 10px;
  border: none;
  border-radius: 12px;
  cursor: pointer;

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

.paginationButton {
  display: block;
  margin-left: -10px;
}
</style>
