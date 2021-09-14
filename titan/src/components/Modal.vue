<template>
  <div class="modalBg" @click="closeModal" />
  <div class="modalContainer">
    <div class="modal">
      <slot />
    </div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  name: "Modal",
  props: {
    coverNavbar: {
      type: Boolean,
      default: true,
    },
  },
  emits: ["close"],
})
export default class Modal extends Vue {
  closeModal(): void {
    this.$emit("close");
  }
}
</script>

<style scoped>
.modalBg {
  width: 100vw;
  height: 100vh;
  background: var(--textPrimary);
  opacity: 75%;
  position: fixed;
  top: 0px;
  cursor: pointer;
  z-index: 100;
}
.modalContainer {
  position: absolute;
  width: 100vw;
  height: 100vh;
  top: 0;
  display: flex;
  justify-content: center;
  align-items: center;
}
.modal {
  position: fixed;
  z-index: 100;
  width: 350px;
  padding: 15px 20px;
  border-radius: 15px;
  background: var(--backgroundSecondary);
}
</style>
