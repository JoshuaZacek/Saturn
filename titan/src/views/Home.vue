<template>
  <SegmentedControl
    class="segmentedControl"
    :segments="Object.keys(postSorts)"
    @change="changePostSort"
  />

  <!-- Post sort heading & time period dropdown -->
  <div v-if="postSorts[currentPostSort]['timePeriodDropdown']" style="width: 550px;">
    <p class="postSortHeadingDropdown">{{ currentPostSort }} posts from:</p>
    <Menu
      style="display: inline-block;"
      :options="timePeriods"
      @select="changeTimePeriod"
    />
  </div>
  <div v-else>
    <p class="postSortHeading">{{ currentPostSort }} posts</p>
  </div>

  <!-- posts -->
  <div>
    <div v-for="post in posts" :key="post.id">
      <Post :post="post" />
    </div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import Menu from "@/components/Menu.vue";
import Post from "@/components/Post.vue";
import axios from "axios";

@Options({
  components: {
    SegmentedControl,
    Menu,
    Post,
  },
})
export default class Home extends Vue {
  postSorts = {
    New: {
      timePeriodDropdown: false,
    },
    Top: {
      timePeriodDropdown: true,
    },
  };
  timePeriods = ["Today", "This Week", "This Month", "This Year", "All Time"];
  currentPostSort = Object.keys(this.postSorts)[0];
  currentTimePeriod = this.timePeriods[0];
  posts: Record<string, unknown>[] = [];

  created(): void {
    const url = this.createPostsURL(this.currentPostSort, this.currentTimePeriod);
    console.log(url);
    this.getPosts(url).then((posts) => {
      this.posts = posts;
    });
  }

  changePostSort(sort: string): void {
    this.currentPostSort = sort;
    this.reloadPosts(this.timePeriods[0], sort);
  }

  changeTimePeriod(timePeriod: string): void {
    this.currentTimePeriod = timePeriod;
    this.reloadPosts(timePeriod, this.currentPostSort);
  }

  // used when a new time period or post sort is selected
  reloadPosts(timePeriod: string, sort: string): void {
    this.posts = [];
    const url = this.createPostsURL(sort, timePeriod);
    console.log(url);
    this.getPosts(url).then((posts) => {
      this.posts = posts;
    });
  }

  // used to create & format the url to fetch posts from the api
  // TO DO: include time periods in url, change time periods from words to unix timestamps
  createPostsURL(sort: string, timePeriod: string): string {
    let timePeriodSeconds;
    if (timePeriod == "Today") {
      timePeriodSeconds = 86400;
    } else if (timePeriod == "This Week") {
      timePeriodSeconds = 604800;
    } else if (timePeriod == "This Month") {
      timePeriodSeconds = 2592000;
    } else if (timePeriod == "This Year") {
      timePeriodSeconds = 31536000;
    } else {
      timePeriodSeconds = 0;
    }
    return `http://localhost:4000/posts/all?sort=${sort}&limit=5${
      timePeriod ? "&time=" + timePeriodSeconds : ""
    }`.toLowerCase();
  }

  // api call for posts
  async getPosts(url: string): Promise<Record<string, unknown>[]> {
    const res = await axios.get(url, { withCredentials: true });
    return res.data.data.posts;
  }
}
</script>

<style scoped>
.postSortHeading {
  margin-top: 4px;
  margin-left: 10px;
  width: 550px;
  margin-bottom: 20px;
}
.postSortHeadingDropdown {
  display: inline-block;
  margin-right: 5px;
  margin-left: 5px;
  margin-bottom: 20px;
}
.segmentedControl {
  margin-top: 30px;
  margin-bottom: 15px;
}
</style>
