<template>
  <Navbar />
  <router-view />
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
  --backgroundPrimary: #fcfcfc;
  --backgroundSecondary: #fff;
  --backgroundTertiary: #efefef;
  --textPrimary: #000;
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
</style>
