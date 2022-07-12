<template>
  <div v-if="!moonStatus" class="banner">
    <h1>/{{ moon.name }}</h1>
    <Button class="bannerButton" @click="this.$router.push({ name: 'CreatePost' })"
      >Create post</Button
    >
  </div>

  <div v-if="!moonStatus">
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

  <div v-if="!moonStatus">
    <Post
      v-for="(post, index) in posts"
      :key="post.id"
      :post="post"
      @delete="posts.splice(index, 1)"
    />
  </div>

  <div :class="['loaderContainer', moonStatus ? 'moon' : 'post']">
    <Loader
      v-if="(moonStatus || postStatus) == 'fetching'"
      :size="40"
      bgColor="#fcfcfc"
      fgColor="#d9d9d9"
    />
    <p v-if="footer">{{ footer }}</p>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import Button from "@/components/Button.vue";
import Menu from "@/components/Menu.vue";
import Post from "@/components/Post.vue";
import Loader from "@/components/Loader.vue";
import axios from "axios";

@Options({
  components: {
    SegmentedControl,
    Button,
    Menu,
    Post,
    Loader,
  },
})
export default class Moon extends Vue {
  sorts = {
    New: {
      timePeriodDropdown: false,
    },
    Top: {
      timePeriodDropdown: true,
    },
  };
  timePeriods = ["Today", "This Week", "This Month", "This Year", "All Time"];
  moonStatus = "fetching";
  postStatus = "";
  footer = "Loading moon";

  currentSort = Object.keys(this.sorts)[0];
  currentTimePeriod = this.timePeriods[0];
  posts: Record<string, unknown>[] = [];
  moon: Record<string, never> = {};
  nextCursor: string | null = null;

  async created(): Promise<void> {
    window.onscroll = () => {
      if (window.innerHeight + window.pageYOffset >= document.body.offsetHeight - 2) {
        if (this.nextCursor && this.postStatus != "fetching") {
          this.getPosts();
        }
      }
    };

    axios
      .get(`http://localhost:4000/moon/${this.$route.params.moon}`)
      .then((res) => {
        this.moon = res.data;
        this.moonStatus = "";

        this.getPosts();
      })
      .catch((err) => {
        if (err?.response?.status == 404) {
          this.$router.replace({ name: "404" });
        } else {
          this.moonStatus = "error";
          this.footer = "Moon couldn't be loaded. Please try again.";
        }
      });
  }

  getPosts(): void {
    this.postStatus = "fetching";
    this.footer = "Loading posts";

    const url = this.createPostsURL(
      this.currentSort,
      this.currentTimePeriod,
      this.moon.name,
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
        this.postStatus = "";

        this.posts = this.posts.concat(res.data.posts);
        this.nextCursor = res.data.next_cursor;
      })
      .catch(() => {
        this.postStatus = "error";
        this.footer = "Posts couldn't be loaded. Please try again.";
      });
  }

  changeSort(sort: string): void {
    this.currentSort = sort;
    this.posts = [];

    this.getPosts();
  }

  changeTimePeriod(timePeriod: string): void {
    this.currentTimePeriod = timePeriod;
    this.posts = [];

    this.getPosts();
  }

  // used to create & format the url to fetch posts from the api
  createPostsURL(
    sort: string,
    timePeriod: string,
    moon: string,
    cursor?: string | null
  ): string {
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
    return `http://localhost:4000/posts/${moon}?sort=${sort.toLowerCase()}&limit=5${
      timePeriod ? "&time=" + timePeriodSeconds : ""
    }${cursor ? "&cursor=" + cursor : ""}`;
  }
}
</script>

<style scoped>
.banner {
  width: 100%;
  height: 175px;
  box-sizing: border-box;
  padding: 15px 20px 20px;

  background: var(--textSecondary);
  color: var(--backgroundSecondary);

  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.bannerButton {
  margin-top: auto;
}

.segmentedControl {
  margin-top: 30px;
}

.sortHeading {
  margin: 20px 0;
}
.sortHeadingWithDropdown {
  display: inline-block;
}
p.sortHeadingWithDropdown {
  margin: 20px 5px 20px 0;
}

.loaderContainer {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;

  color: #d9d9d9;
}
.loaderContainer.post {
  margin-top: 10px;
  margin-bottom: 30px;
}
.loaderContainer.moon {
  position: absolute;
  top: calc(50% + 25px);
  transform: translateY(-50%);
}
</style>
