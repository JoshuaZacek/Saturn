<template>
  <div class="background" @click.self="if (easyCloseMode) close();">
    <div class="modal">
      <CloseButton v-if="easyCloseMode" @click="close" />

      <slot></slot>
    </div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";
import CloseButton from "@/components/CloseButton.vue";

@Options({
  name: "Modal",
  emits: ["close"],
  components: {
    Button,
    CloseButton,
  },
  props: {
    easyCloseMode: {
      type: Boolean,
      default: true,
    },
  },
})
export default class Modal extends Vue {
  easyCloseMode!: boolean;

  handler(e: KeyboardEvent): void {
    if (e.code == "Escape") this.close();
  }

  created(): void {
    if (this.easyCloseMode) window.addEventListener("keydown", this.handler);
  }
  beforeUnmount(): void {
    if (this.easyCloseMode) window.removeEventListener("keydown", this.handler);
  }

  close(): void {
    this.$emit("close");
  }
}
</script>

<style scoped>
.background {
  background-color: rgba(0, 0, 0, 0.75);

  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 100;

  display: flex;
  justify-content: center;
  align-items: center;
}
.modal {
  width: 350px;
  padding: 15px 20px 20px;
  border-radius: 20px;
  background: var(--backgroundSecondary);
  position: relative;
}
</style>
