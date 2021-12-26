<template>
  <div class="postContainer">
    <h3>{{ post.title }}</h3>
    <div class="postInfo">
      <p
        style="cursor: pointer"
        @click="this.$router.push({ name: 'Moon', params: { moon: post.moon.name } })"
      >
        <strong>/{{ post.moon.name }}</strong>
      </p>

      <span>//</span>
      <p style="color: var(--textSecondary)">{{ post.user.username }}</p>

      <span>//</span>
      <p style="color: var(--textSecondary)">
        {{ timeSince(new Date(post.inserted_at)) }}
      </p>
    </div>

    <p class="postBody">{{ post.body }}</p>

    <div class="voteButtons">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14.07 12.94">
        <g id="Layer_2" data-name="Layer 2">
          <g id="Layer_1-2" data-name="Layer 1">
            <path
              :class="[upvote ? 'upvote' : '', 'cls-1']"
              @click="vote('up')"
              d="M5,1.94C6.13,0,8,0,9.06,1.94l4,7c1.11,1.93.2,3.5-2,3.5H3c-2.23,0-3.14-1.57-2-3.5Z"
            />
          </g>
        </g>
      </svg>
      <span>{{ post.votes }}</span>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14.07 12.94">
        <g id="Layer_2" data-name="Layer 2">
          <g id="Layer_1-2" data-name="Layer 1">
            <path
              :class="[downvote ? 'downvote' : '', 'cls-1']"
              @click="vote('down')"
              d="M9.06,11C8,12.93,6.13,12.93,5,11L1,4C-.14,2.07.77.5,3,.5h8.08c2.22,0,3.13,1.57,2,3.5Z"
            />
          </g>
        </g>
      </svg>
    </div>
  </div>
</template>

<script lang="ts">
import axios from "axios";
import { Options, Vue } from "vue-class-component";
@Options({
  props: {
    post: Object,
  },
})
export default class Post extends Vue {
  upvote = false;
  downvote = false;
  post!: Record<string, unknown>;

  created(): void {
    if (this.post.hasVoted === 1) {
      this.upvote = true;
    } else if (this.post.hasVoted === -1) {
      this.downvote = true;
    }
  }

  deleteVote(): void {
    axios
      .delete(`http://localhost:4000/vote?post_id=${this.post.id}`, {
        withCredentials: true,
      })
      .then(() => {
        if (this.upvote) {
          (<number>this.post.votes) -= 1;
        } else if (this.downvote) {
          (<number>this.post.votes) += 1;
        }
        this.upvote = false;
        this.downvote = false;
      });
  }

  vote(vote: string): void {
    if (vote == "up") {
      axios
        .post(
          `http://localhost:4000/vote?vote=up&post_id=${this.post.id}`,
          {},
          {
            withCredentials: true,
          }
        )
        .then(() => {
          if (this.downvote) {
            (<number>this.post.votes) += 2;
            this.upvote = true;
            this.downvote = false;
          } else if (this.upvote) {
            this.deleteVote();
          } else {
            (<number>this.post.votes) += 1;
            this.upvote = true;
            this.downvote = false;
          }
        })
        .catch((err) => {
          console.log(err);
        });
      //downvote
    } else if (vote == "down") {
      axios
        .post(
          `http://localhost:4000/vote?vote=down&post_id=${this.post.id}`,
          {},
          {
            withCredentials: true,
          }
        )
        .then(() => {
          if (this.upvote) {
            (<number>this.post.votes) -= 2;
            this.upvote = false;
            this.downvote = true;
          } else if (this.downvote) {
            this.deleteVote();
          } else {
            (<number>this.post.votes) -= 1;
            this.upvote = false;
            this.downvote = true;
          }
        })
        .catch((err) => {
          console.log(err);
        });
    }
  }

  //relative time caluclator
  timeSince(timeStamp: number): string {
    //time constants
    const second = 1;
    const minute = second * 60;
    const hour = minute * 60;
    const day = hour * 24;
    const month = day * 30;
    const year = day * 365;

    const timePassed = (Date.now() - timeStamp) / 1000;
    if (timePassed < minute) {
      let interval = Math.floor(timePassed);
      return interval == 1 ? "1 second ago" : `${interval} seconds ago`;
    } else if (timePassed < hour) {
      let interval = Math.floor(timePassed / minute);
      return interval == 1 ? "1 minute ago" : `${interval} minutes ago`;
    } else if (timePassed < day) {
      let interval = Math.floor(timePassed / hour);
      return interval == 1 ? "1 hour ago" : `${interval} hours ago`;
    } else if (timePassed < month) {
      let interval = Math.floor(timePassed / day);
      return interval == 1 ? "1 day ago" : `${interval} days ago`;
    } else if (timePassed < year) {
      let interval = Math.floor(timePassed / month);
      return interval == 1 ? "1 month ago" : `${interval} months ago`;
    } else {
      let interval = Math.floor(timePassed / year);
      return interval == 1 ? "1 year ago" : `${interval} years ago`;
    }
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
.postInfo {
  font-size: 14px;
  margin-top: 1px;
}
.postInfo > * {
  display: inline-block;
}
.postInfo > span {
  color: var(--textSecondary);
  margin: 0px 7px;
}

.postBody {
  margin-top: 10px;
}

.voteButtons > * {
  display: inline-block;
  margin-top: 15px;
}
.voteButtons > span {
  margin: 0px 7px;
  font-size: 15px;
}

.cls-1 {
  fill: none;
  stroke: #757575;
  stroke-linejoin: round;
  cursor: pointer;
}
.cls-1:hover {
  fill: #757575;
}
.upvote {
  fill: #006cff;
  stroke: #006cff;
  stroke-linejoin: round;
}
.upvote:hover {
  fill: #006cff;
}
.downvote {
  fill: red;
  stroke: red;
  stroke-linejoin: round;
}
.downvote:hover {
  fill: red;
}

svg {
  height: 15px;
}
</style>
