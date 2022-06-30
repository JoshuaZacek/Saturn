<template>
  <div v-if="loadingProfile">
    <Loader :size="40" bgColor="#fcfcfc" fgColor="#d9d9d9" />
    <p>Loading profile...</p>
  </div>

  <div v-if="!loadingProfile" class="profileBanner">
    <h1>@{{ userDetails.username }}</h1>
  </div>

  <div v-if="!loadingProfile" class="profileContainer">
    <SegmentedControl
      class="segmentedControl"
      :segments="['Overview', 'Posts', 'Comments']"
      @change="changeContentType"
    />

    <div class="sortDropdown">
      <p>Sort {{ currentContentType }} by:</p>
      <Menu :options="['New', 'Top']" @select="changeContentSort" />
    </div>

    <div v-for="content in profileContent" :key="content.id">
      <Post
        v-if="content.type == 'post' || currentContentType == 'posts'"
        :post="content"
      />
      <CommentProfile
        v-if="content.type == 'comment' || currentContentType == 'comments'"
        :comment="content"
      />
    </div>

    <div v-if="loadingContent && !loadingProfile">
      <Loader :size="30" bgColor="#ffffff" fgColor="#d9d9d9" />
    </div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import Menu from "@/components/Menu.vue";
import CommentProfile from "@/components/CommentProfile.vue";
import Post from "@/components/Post.vue";
import Loader from "@/components/Loader.vue";
import axios from "axios";
import { AxiosError } from "axios";

@Options({
  components: {
    SegmentedControl,
    Menu,
    CommentProfile,
    Post,
    Loader,
  },
})
export default class Profile extends Vue {
  currentContentType = "overview";
  currentContentSort = "new";
  loadingProfile = true;
  loadingContent = true;
  profileContent: Record<string, unknown>[] = [];
  userDetails!: Record<string, never>;
  nextCursor: string | null = null;

  async created(): Promise<void> {
    try {
      const res = await axios.get(
        `http://localhost:4000/user/${this.$route.params.username}`
      );
      this.userDetails = res.data;
    } catch (err) {
      if ((<AxiosError>err).response?.status == 404) {
        this.$router.replace({ name: "404" });
      } else {
        throw err;
      }
    }
    this.loadingProfile = false;

    this.fetchProfileContent(
      this.userDetails.id,
      this.currentContentType,
      this.currentContentSort,
      this.nextCursor
    ).then(([content, nextCursor]) => {
      this.profileContent = <Record<string, unknown>[]>content;
      this.nextCursor = <string | null>nextCursor;
    });
    this.loadingContent = false;

    window.onscroll = () => {
      if (window.innerHeight + window.pageYOffset >= document.body.offsetHeight - 2) {
        if (this.nextCursor && !this.loadingContent) {
          this.loadingContent = true;

          this.fetchProfileContent(
            this.userDetails.id,
            this.currentContentType,
            this.currentContentSort,
            this.nextCursor
          ).then(([content, nextCursor]) => {
            this.profileContent = this.profileContent.concat(
              <Record<string, unknown>[]>content
            );
            this.nextCursor = <string | null>nextCursor;
            this.loadingContent = false;
          });
        }
      }
    };
  }

  async fetchProfileContent(
    user_id: number,
    type: string,
    sort: string,
    cursor: string | null
  ): Promise<(Record<string, unknown>[] | string | null)[]> {
    const res = await axios.get(
      `http://localhost:4000/profile/${user_id}/${type}?sort=${sort}&limit=5${
        cursor ? `&cursor=${cursor}` : ""
      }`
    );
    return [res.data.content, res.data.next_cursor];
  }

  changeContentType(type: string): void {
    this.profileContent = [];
    this.nextCursor = null;
    this.currentContentType = type.toLowerCase();

    this.fetchProfileContent(
      this.userDetails.id,
      this.currentContentType,
      this.currentContentSort,
      this.nextCursor
    ).then(([content, nextCursor]) => {
      this.profileContent = <Record<string, unknown>[]>content;
      this.nextCursor = <string | null>nextCursor;
    });
  }

  changeContentSort(sort: string): void {
    this.profileContent = [];
    this.nextCursor = null;
    this.currentContentSort = sort.toLowerCase();

    this.fetchProfileContent(
      this.userDetails.id,
      this.currentContentType,
      this.currentContentSort,
      this.nextCursor
    ).then(([content, nextCursor]) => {
      this.profileContent = <Record<string, unknown>[]>content;
      this.nextCursor = <string | null>nextCursor;
    });
  }
}
</script>

<style scoped>
.profileBanner {
  width: 100%;
  height: 175px;
  background: var(--textSecondary);
  color: var(--backgroundSecondary);
  padding: 15px 20px 20px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
}
.segmentedControl {
  margin: 30px 0px 15px;
}
.sortDropdown > * {
  display: inline-block;
}
.sortDropdown > p {
  margin: 0px 5px 20px;
}
.sortDropdown {
  width: 550px;
}
</style>
