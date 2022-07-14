<template>
  <div class="background" @click.self="if (easyCloseMode) close();">
    <div class="modal" ref="modal">
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
  firstFocusable!: HTMLElement;
  lastFocusable!: HTMLElement;
  declare $refs: {
    modal: HTMLDivElement;
  };

  handler(e: KeyboardEvent): void {
    if (e.code == "Escape" && this.easyCloseMode) {
      this.close();
    }
    if (e.code == "Tab") {
      if (e.shiftKey && document.activeElement == this.firstFocusable) {
        this.firstFocusable.focus();
        e.preventDefault();
      } else if (!e.shiftKey && document.activeElement == this.lastFocusable) {
        this.lastFocusable.focus();
        e.preventDefault();
      }
    }
  }

  mounted(): void {
    document.addEventListener("keydown", this.handler);

    const modal = this.$refs.modal;
    const focusableElements = modal.querySelectorAll(
      'a[href], button, input, textarea, select, details, [tabindex]:not([tabindex="-1"])'
    );

    this.firstFocusable = <HTMLElement>focusableElements[0];
    this.lastFocusable = <HTMLElement>focusableElements[focusableElements.length - 1];

    this.firstFocusable.focus();
  }
  beforeUnmount(): void {
    document.removeEventListener("keydown", this.handler);
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
