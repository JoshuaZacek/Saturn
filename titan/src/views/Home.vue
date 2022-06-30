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
    <div v-for="(post, index) in posts" :key="post.id">
      <Post :post="post" @delete="posts.splice(index, 1)" />
    </div>
  </div>

  <Loader
    v-if="fetchingPosts"
    :size="40"
    bgColor="#fcfcfc"
    fgColor="#d9d9d9"
    class="footerLoader"
  />
  <p v-if="!nextCursor && !posts.length" class="footerText">Hmmm... empty</p>
  <p v-else-if="!nextCursor && !fetchingPosts" class="footerText">That's all folks</p>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import Menu from "@/components/Menu.vue";
import Post from "@/components/Post.vue";
import Loader from "@/components/Loader.vue";
import axios from "axios";

@Options({
  components: {
    SegmentedControl,
    Menu,
    Post,
    Loader,
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
  fetchingPosts = false;
  currentPostSort = Object.keys(this.postSorts)[0];
  currentTimePeriod = this.timePeriods[0];
  posts: Record<string, unknown>[] = [];
  nextCursor: string | null = null;

  created(): void {
    window.onscroll = () => {
      if (window.innerHeight + window.pageYOffset >= document.body.offsetHeight - 2) {
        this.fetchMorePosts();
      }
    };

    const url = this.createPostsURL(this.currentPostSort, this.currentTimePeriod);
    this.getPosts(url).then(([posts, nextCursor]) => {
      this.posts = <Record<string, unknown>[]>posts;
      this.nextCursor = <string | null>nextCursor;
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
    this.getPosts(url).then(([posts, nextCursor]) => {
      this.posts = <Record<string, unknown>[]>posts;
      this.nextCursor = <string | null>nextCursor;
    });
  }

  fetchMorePosts(): void {
    if (this.nextCursor && !this.fetchingPosts) {
      this.fetchingPosts = true;

      const url = this.createPostsURL(
        this.currentPostSort,
        this.currentTimePeriod,
        this.nextCursor
      );
      this.getPosts(url).then(([posts, nextCursor]) => {
        this.posts = this.posts.concat(<Record<string, unknown>[]>posts);
        this.nextCursor = <string | null>nextCursor;
        this.fetchingPosts = false;
      });
    }
  }

  // used to create & format the url to fetch posts from the api
  createPostsURL(sort: string, timePeriod: string, cursor?: string | null): string {
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
    return `http://localhost:4000/posts/all?sort=${sort.toLowerCase()}&limit=5${
      timePeriod ? "&time=" + timePeriodSeconds : ""
    }${cursor ? "&cursor=" + cursor : ""}`;
  }

  // api call for posts
  async getPosts(url: string): Promise<(Record<string, unknown>[] | string | null)[]> {
    const res = await axios.get(url, { withCredentials: true });
    return [res.data.posts, res.data.next_cursor];
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
.footerText {
  color: #d9d9d9;
  margin-top: 20px;
  margin-bottom: 40px;
}
.footerLoader {
  margin-top: 20px;
  margin-bottom: 40px;
}
</style>
