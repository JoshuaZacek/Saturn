<template>
  <div class="segmentedContainer">
    <SegmentedControl
      class="segmentedControl"
      :segments="Object.keys(sorts)"
      @change="changeSort"
    />

    <div v-if="sorts[currentSort].timePeriodDropdown">
      <p class="sortHeadingWithDropdown">{{ currentSort }} posts from:</p>
      <Menu
        class="sortHeadingWithDropdown"
        :options="timePeriods"
        @select="changeTimePeriod"
      />
    </div>
    <p v-else class="sortHeading">{{ currentSort }} posts</p>
  </div>

  <Post
    v-for="(post, index) in posts"
    :key="post.id"
    :post="post"
    @delete="posts.splice(index, 1)"
  />

  <Loader
    v-if="fetchingPosts"
    :size="40"
    bgColor="#fcfcfc"
    fgColor="#d9d9d9"
    class="loader"
  />
  <p v-if="footer" class="footer">{{ footer }}</p>
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
  sorts = {
    New: {
      timePeriodDropdown: false,
    },
    Top: {
      timePeriodDropdown: true,
    },
  };
  timePeriods = ["Today", "This Week", "This Month", "This Year", "All Time"];
  fetchingPosts = true;
  footer = "Loading posts";

  currentSort = Object.keys(this.sorts)[0];
  currentTimePeriod = this.timePeriods[0];
  posts: Record<string, unknown>[] = [];
  nextCursor: string | null = null;

  created(): void {
    window.onscroll = () => {
      if (window.innerHeight + window.pageYOffset >= document.body.offsetHeight - 2) {
        if (this.nextCursor && !this.fetchingPosts) {
          this.getPosts();
        }
      }
    };

    this.getPosts();
  }

  getPosts(): void {
    this.fetchingPosts = true;
    this.footer = "Loading posts";

    const url = this.createPostsURL(
      this.currentSort,
      this.currentTimePeriod,
      this.nextCursor
    );

    axios
      .get(url, { withCredentials: true })
      .then((res) => {
        if (!res.data.posts.length && !res.data.next_cursor) {
          this.footer = "Hmmm... empty";
        } else if (!res.data.next_cursor) {
          this.footer = "That's all folks";
        } else {
          this.footer = "";
        }
        this.fetchingPosts = false;

        this.posts = this.posts.concat(res.data.posts);
        this.nextCursor = res.data.next_cursor;
      })
      .catch(() => {
        this.fetchingPosts = false;
        this.footer = "Posts couldn't be loaded. Please try again.";
      });
  }

  changeSort(sort: string): void {
    this.currentSort = sort;
    this.nextCursor = null;
    this.posts = [];

    this.getPosts();
  }

  changeTimePeriod(timePeriod: string): void {
    this.currentTimePeriod = timePeriod;
    this.nextCursor = null;
    this.posts = [];

    this.getPosts();
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
    return `${process.env.VUE_APP_API_URL}/posts/?sort=${sort.toLowerCase()}&limit=5${
      timePeriod ? "&time_period=" + timePeriodSeconds : ""
    }${cursor ? "&cursor=" + cursor : ""}`;
  }
}
</script>

<style scoped>
.sortHeading {
  margin: 20px 0;
}
.sortHeadingWithDropdown {
  display: inline-block;
}
p.sortHeadingWithDropdown {
  margin: 20px 5px 20px 0;
}

.footer {
  color: #d9d9d9;
  margin-top: 10px;
  margin-bottom: 30px;
}
.loader {
  margin-top: 10px;
}
.segmentedContainer {
  width: 550px;
  position: relative;
}

@media screen and (max-width: 590px) {
  .segmentedContainer {
    width: calc(100% - 40px);
  }
}
</style>
