<template>
  <Overlay v-if="overlayStatus" :status="overlayStatus" :message="overlayMessage" />

  <div class="voteButtons">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
      <path
        d="M659.21,143.52c-82.32-141.36-218.55-141.36-295.78,0L72,653.61c-80.86,140.64-14.57,255,145.71,255H804.92c162.46,0,228.76-114.4,145.7-255Z"
        style="fill:none;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
        :class="[currentVote == 'up' ? 'up' : '', 'vote']"
        @click="submitVote('up')"
      />
    </svg>

    <p>{{ content.votes }}</p>

    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 946.15">
      <path
        d="M364.79,802.63C447.11,944,583.34,944,660.57,802.63L952,292.54c80.86-140.64,14.57-255-145.71-255H219.08c-162.46,0-228.76,114.41-145.7,255Z"
        style="fill:none;stroke:#757575;stroke-miterlimit:10;stroke-width:75px;cursor:pointer;"
        :class="[currentVote == 'down' ? 'down' : '', 'vote']"
        @click="submitVote('down')"
      />
    </svg>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Overlay from "@/components/Overlay.vue";
import axios from "axios";

@Options({
  props: {
    content: Object,
    type: String,
  },
  components: {
    Overlay,
  },
})
export default class VoteButtons extends Vue {
  currentVote = "";
  overlayMessage = "";
  overlayStatus = "";

  content!: Record<string, unknown>;
  type!: string;

  created(): void {
    if (this.content.hasVoted === 1) {
      this.currentVote = "up";
    } else if (this.content.hasVoted === -1) {
      this.currentVote = "down";
    }
  }

  createSubmitURL(vote: string): string {
    return `http://localhost:4000/vote?vote=${vote}&${
      this.type == "post" ? "post_id" : "comment_id"
    }=${this.content.id}`;
  }

  createDeleteURL(): string {
    return `http://localhost:4000/vote?${
      this.type == "post" ? "post_id" : "comment_id"
    }=${this.content.id}`;
  }

  async setOverlay(status: string, message: string, autoClear = true): Promise<void> {
    this.overlayStatus = status;
    this.overlayMessage = message;

    if (autoClear) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.setOverlay("", "", false);
    }
  }

  deleteVote(): void {
    axios
      .delete(this.createDeleteURL(), { withCredentials: true })
      .then(() => {
        if (this.currentVote == "up") {
          (<number>this.content.votes) -= 1;
        } else if (this.currentVote == "down") {
          (<number>this.content.votes) += 1;
        }

        this.currentVote = "";
        this.setOverlay("success", "Vote submitted");
      })
      .catch(() => {
        this.setOverlay("error", "Vote couldn't be submitted");
      });
  }

  submitVote(vote: string): void {
    this.setOverlay("load", "Submiting your vote", false);

    if (vote == this.currentVote) {
      this.deleteVote();
      return;
    }

    axios
      .post(this.createSubmitURL(vote), {}, { withCredentials: true })
      .then(() => {
        this.setOverlay("success", "Vote submitted");

        if (vote == "up") {
          if (this.currentVote == "down") {
            (<number>this.content.votes) += 2;
          } else {
            (<number>this.content.votes) += 1;
          }

          this.currentVote = "up";
        } else if (vote == "down") {
          if (this.currentVote == "up") {
            (<number>this.content.votes) -= 2;
          } else {
            (<number>this.content.votes) -= 1;
          }

          this.currentVote = "down";
        }
      })
      .catch(() => {
        this.setOverlay("error", "Vote couldn't be submitted");
      });
  }
}
</script>

<style scoped>
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
</style>
