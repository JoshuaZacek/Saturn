<template>
  <div v-if="!loadingProfile" class="profileBanner">
    <h1>@{{ userDetails.username }}</h1>
  </div>

  <div v-if="!loadingProfile" class="profileContainer">
    <div class="segmentedContainer">
      <SegmentedControl
        class="segmentedControl"
        :segments="contentTypes"
        @change="changeContentType"
      />

      <div class="sortDropdown">
        <p>Sort {{ currentContentType }} by:</p>
        <Menu :options="contentSorts" @select="changeContentSort" />
      </div>
    </div>

    <div
      v-for="(content, index) in profileContent"
      :key="content.id"
      class="contentContainer"
    >
      <Post
        v-if="content.contentType == 'post' || currentContentType == 'posts'"
        :post="content"
        @delete="profileContent.splice(index, 1)"
      />
      <CommentProfile
        v-if="content.contentType == 'comment' || currentContentType == 'comments'"
        :comment="content"
      />
    </div>
  </div>

  <div v-if="!loadingProfile && !loadingContent">
    <p v-if="!nextCursor && profileContent.length == 0" class="footer">Hmmm... empty</p>
    <p v-else-if="!nextCursor" class="footer">
      That's all folks
    </p>
  </div>

  <div
    v-if="loadingProfile || loadingContent"
    :class="['loaderContainer', loadingProfile ? 'profile' : 'content']"
  >
    <Loader v-if="!error" :size="40" bgColor="#fcfcfc" fgColor="#d9d9d9" />

    <p v-if="error">{{ error }}</p>
    <p v-else>
      {{ loadingProfile ? "Loading profile" : "Loading content" }}
    </p>
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
  contentTypes = ["Overview", "Posts", "Comments"];
  currentContentType = this.contentTypes[0].toLowerCase();
  contentSorts = ["New", "Top"];
  currentContentSort = this.contentSorts[0].toLowerCase();
  loadingProfile = true;
  loadingContent = false;
  error = "";

  profileContent: Record<string, unknown>[] = [];
  userDetails!: Record<string, never>;
  nextCursor: string | null = null;

  created(): void {
    axios
      .get(`${process.env.VUE_APP_API_URL}user/${this.$route.params.username}`)
      .then((res) => {
        this.userDetails = res.data;
        this.loadingProfile = false;

        this.fetchProfileContent();
      })
      .catch((err) => {
        if (err.response?.status == 404) {
          this.$router.replace({ name: "404" });
        } else {
          this.error = "Profile couldn't be loaded";
        }
      });

    window.onscroll = async () => {
      if (window.innerHeight + window.pageYOffset >= document.body.offsetHeight - 2) {
        if (this.nextCursor && !this.loadingContent && !this.loadingProfile) {
          await this.fetchProfileContent();
        }
      }
    };
  }

  async fetchProfileContent(): Promise<void> {
    this.loadingContent = true;

    const user_id = this.userDetails.id;
    const type = this.currentContentType;
    const sort = this.currentContentSort;
    const cursor = this.nextCursor;

    await axios
      .get(
        `${
          process.env.VUE_APP_API_URL
        }profile/${type}?user_id=${user_id}&sort=${sort}&limit=5${
          cursor ? `&cursor=${cursor}` : ""
        }`,
        { withCredentials: true }
      )
      .then((res) => {
        this.profileContent = this.profileContent.concat(res.data.content);
        this.nextCursor = res.data.next_cursor;

        this.loadingContent = false;
      })
      .catch(() => (this.error = "Content couldn't be loaded"));
  }

  changeContentType(type: string): void {
    this.profileContent = [];
    this.nextCursor = null;
    this.currentContentType = type.toLowerCase();

    this.fetchProfileContent();
  }

  changeContentSort(sort: string): void {
    this.profileContent = [];
    this.nextCursor = null;
    this.currentContentSort = sort.toLowerCase();

    this.fetchProfileContent();
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

.footer {
  color: #d9d9d9;
  margin-top: 10px;
  margin-bottom: 30px;
}

.loaderContainer {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;

  color: #d9d9d9;
}
.loaderContainer.content {
  margin-top: 10px;
  margin-bottom: 30px;
}
.loaderContainer.profile {
  position: absolute;
  top: calc(50% + 25px);
  transform: translateY(-50%);
}

.segmentedContainer {
  width: 550px;
  position: relative;
}

.profileContainer {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.contentContainer {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}

@media screen and (max-width: 590px) {
  .segmentedContainer {
    width: calc(100% - 40px);
  }
}
</style>
