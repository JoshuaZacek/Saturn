<template>
  <Navbar />
  <div class="flexContainer">
    <router-view :key="$route.fullPath" />
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Navbar from "@/components/Navbar.vue";

@Options({
  components: {
    Navbar,
  },
})
export default class App extends Vue {}
</script>

<style>
:root {
  --backgroundPrimary: #fcfcfc; /* the background colour */
  --backgroundSecondary: #fff; /* colour for main elements against background */
  --backgroundTertiary: #efefef; /* colur for elements against a main element */
  --textPrimary: #000; /* primary text colour */
  --textSecondary: #757575; /* secondary text colour */
  --textTertiary: #d9d9d9; /* tertiary text colour */
}

body {
  width: 100%;
  height: 100%;
  background: var(--backgroundPrimary);
}

* {
  margin: 0;
  padding: 0;
}

#app {
  font-family: "Helvetica Neue", Helvetica, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

.flexContainer {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
