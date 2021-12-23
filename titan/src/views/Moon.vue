<template>
  <div class="banner">
    <h1>/{{ moon.name }}</h1>
    <Button class="bannerButton" @click="this.$router.push({ name: 'CreatePost' })"
      >Create post</Button
    >
  </div>
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
import Button from "@/components/Button.vue";
import Menu from "@/components/Menu.vue";
import Post from "@/components/Post.vue";
import axios from "axios";
import { RouteLocationNormalized, NavigationGuardNext } from "vue-router";

@Options({
  components: {
    SegmentedControl,
    Button,
    Menu,
    Post,
  },
  beforeRouteEnter(
    to: RouteLocationNormalized,
    _from: RouteLocationNormalized,
    next: NavigationGuardNext
  ): void {
    axios
      .get(`http://localhost:4000/moon/${to.params.moon}`)
      .then((res) => {
        next((vm) => {
          // Needed so Typescript doesn't freak out
          (<Record<string, unknown>>(<unknown>vm)).moon = res.data;
        });
      })
      .catch((err) => {
        if (err.response.status == 404) {
          next("/404");
        } else {
          throw err;
        }
      });
  },
})
export default class Moon extends Vue {
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
  moon: Record<string, never> = {};

  created(): void {
    const url = this.createPostsURL(
      this.currentPostSort,
      this.currentTimePeriod,
      this.$route.params.moon
    );
    console.log(url);
    this.getPosts(url).then((posts) => {
      this.posts = posts;
    });
  }

  changePostSort(sort: string): void {
    this.currentPostSort = sort;
    this.reloadPosts(this.currentTimePeriod, sort);
  }

  changeTimePeriod(timePeriod: string): void {
    this.currentTimePeriod = timePeriod;
    this.reloadPosts(timePeriod, this.currentPostSort);
  }

  // used when a new time period or post sort is selected
  reloadPosts(timePeriod: string, sort: string): void {
    this.posts = [];
    const url = this.createPostsURL(sort, timePeriod, this.$route.params.moon);
    console.log(url);
    this.getPosts(url).then((posts) => {
      this.posts = posts;
    });
  }

  // used to create & format the url to fetch posts from the api
  // TO DO: include time periods in url, change time periods from words to unix timestamps
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  createPostsURL(sort: string, timePeriod: string, moon: string | string[]): string {
    return `http://localhost:4000/moon/${moon}/posts?sort=${sort}&limit=5`.toLowerCase();
  }

  // api call for posts
  async getPosts(url: string): Promise<Record<string, unknown>[]> {
    const res = await axios.get(url, { withCredentials: true });
    return res.data.data.posts;
  }
}
</script>

<style scoped>
.banner {
  width: 100%;
  height: 175px;
  background: var(--textSecondary);
  padding: 15px 20px 20px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
}
.bannerButton {
  margin-top: auto;
  align-self: flex-start;
}
h1 {
  color: var(--backgroundSecondary);
}
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
