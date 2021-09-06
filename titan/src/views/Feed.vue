<template>
  <SegmentedControl
    style="margin-top: 30px;"
    :segments="Object.keys(views)"
    @change="changeView"
  />
  <PostView :views="views" :selected="currentView" style="margin-top: 15px;" />
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import SegmentedControl from "@/components/SegmentedControl.vue";
import PostView from "@/components/PostView.vue";

@Options({
  components: {
    SegmentedControl,
    PostView,
  },
})
export default class Feed extends Vue {
  changeView(view: string): void {
    this.currentView = view;
  }

  views = {
    Top: {
      sortDropdown: true,
    },
    New: {
      sortDropdown: true,
    },
    Popular: {},
  };
  currentView = "Top";
}
</script>
