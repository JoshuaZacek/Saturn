<template>
  <div class="overlay">
    <Loader v-if="status == 'load'" :size="40" bgColor="transparent" fgColor="#ffffff" />
    <img v-else-if="status == 'success'" src="/tick.svg" height="40" />
    <img v-else-if="status == 'error'" src="/error.svg" height="40" />

    <!-- <p>{{ status }}</p> -->
    <p>{{ message }}</p>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Loader from "@/components/Loader.vue";

@Options({
  props: {
    status: String,
    message: String,
  },
  components: {
    Loader,
  },
})
export default class Overlay extends Vue {}
</script>

<style scoped>
.overlay {
  background-color: rgba(0, 0, 0, 0.9);
  z-index: 100;
  backdrop-filter: blur(4px);
  box-shadow: 0px 0px 15px rgba(0, 0, 0, 0.2);

  color: white;
  font-weight: 500;

  width: 250px;
  height: 200px;
  border-radius: 15px;

  position: fixed;
  top: 50%;
  left: 50%;
  margin: -100px 0 0 -125px;

  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  gap: 15px;
}

p {
  display: block;
}
</style>
