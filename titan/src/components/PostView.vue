<template>
  <div v-if="views[selectedView]['sortDropdown']" style="width: 550px;">
    <p style="display: inline-block; margin-right: 5px; margin-left: 5px;">
      {{ selectedView }} posts from:
    </p>
    <Menu style="display: inline-block;" :options="menuOptions" @change="changeSort" />
  </div>
  <div v-else>
    <p style="width: 550px; margin-top: 4px; margin-left: 10px;">
      {{ selectedView }} posts
    </p>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Menu from "@/components/Menu.vue";

@Options({
  name: "PostView",
  components: {
    Menu,
  },
  props: {
    views: Object,
    selectedView: String,
    moon: {
      type: String,
      default: "all",
    },
    sort: String,
  },
  watch: {
    selectedView: "changeView",
  },
})
export default class PostView extends Vue {
  declare views: {
    [key: string]: Record<string, unknown>;
  };
  moon!: string;
  selectedView!: string;
  selectedMenuOption!: string;
  menuOptions = ["Today", "This Week", "This Month", "This Year", "All Time"];

  // Create and format url for posts endpoint
  createPostsURL(view: string, sort: string, moon: string): string {
    return `api.localhost/moon/${moon}/posts/${view}${sort ? "&sort=" + sort : ""}`
      .toLowerCase()
      .replace(" ", "");
  }

  // template code. WILL BE REPLACED WITH WORKING CODE
  // ===================
  changeView(): void {
    if (!this.views[this.selectedView]["sortDropdown"]) {
      this.selectedMenuOption = "";
    } else if (!this.menuOptions.includes(this.selectedMenuOption)) {
      this.selectedMenuOption = this.menuOptions[0];
    }

    const url = this.createPostsURL(
      this.selectedView,
      this.selectedMenuOption,
      this.moon
    );
    console.log(url);
  }

  changeSort(option: string): void {
    this.selectedMenuOption = option;
    const url = this.createPostsURL(
      this.selectedView,
      this.selectedMenuOption,
      this.moon
    );
    console.log(url);
  }
  // ===================

  // default posts
  mounted(): void {
    // Select today by default
    this.selectedMenuOption = this.menuOptions[0];

    const url = this.createPostsURL(
      this.selectedView,
      this.selectedMenuOption,
      this.moon
    );
    console.log(url);
  }
}
</script>
