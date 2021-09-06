<template>
  <div v-if="views[selected]['sortDropdown']">
    <p style="display: inline-block; margin-right: 5px;">
      {{ selected }} posts from:
    </p>
    <Menu
      style="display: inline-block;"
      :options="sortOptions"
      @change="changeSort"
    />
  </div>
  <div v-else>
    <p>{{ selected }} posts</p>
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
    selected: String,
    moon: {
      type: String,
      default: "all",
    },
    sort: String,
  },
  watch: {
    selected: "changeView",
  },
})
export default class PostView extends Vue {
  declare views: {
    [key: string]: Record<string, unknown>;
  };
  moon!: string;
  selected!: string;
  sortOptions = ["Today", "This Week", "This Month", "This Year", "All Time"];

  // template code. WILL BE REPLACED WITH WORKING CODE
  changeView(view: string): void {
    if (this.views[view]["sortDropdown"]) {
      console.log(
        `api.localhost/moon/${this.moon}/posts/${view}&sort=${this.sortOptions[0]}`
          .toLowerCase()
          .replace(" ", "")
      );
    } else {
      console.log(
        `api.localhost/moon/${this.moon}/posts/${view}`.toLowerCase()
      );
    }
  }

  changeSort(option: string): void {
    console.log(
      `api.localhost/moon/${this.moon}/posts/${this.selected}&sort=${option}`
        .toLowerCase()
        .replace(" ", "")
    );
  }

  mounted(): void {
    if (this.views[this.selected]["sortDropdown"]) {
      console.log(
        `api.localhost/moon/${this.moon}/posts/${this.selected}&sort=${this.sortOptions[0]}`
          .toLowerCase()
          .replace(" ", "")
      );
    } else {
      console.log(
        `api.localhost/moon/${this.moon}/posts/${this.selected}`.toLowerCase()
      );
    }
  }
}
</script>
