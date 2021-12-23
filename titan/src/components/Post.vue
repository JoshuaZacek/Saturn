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
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
@Options({
  props: {
    post: Object,
  },
})
export default class Post extends Vue {
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
</style>
