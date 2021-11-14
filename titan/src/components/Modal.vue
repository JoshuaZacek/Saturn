<template>
  <div class="modalBackground" tabindex="1" @click="close()">
    <div class="modal" @click.stop>
      <div class="closeButton" @click="close()">
        <div></div>
        <div></div>
      </div>

      <h2>{{ title }}</h2>
      <p class="message"><slot name="message" /></p>

      <div class="modalContent">
        <!-- This slot is for custom content under the message and above the buttons -->
        <slot name="content" />
      </div>

      <div v-if="twoButtons">
        <Button width="165px" style="margin-right: 20px;" @click="buttonClick(1)"
          ><slot name="primaryButton"
        /></Button>
        <Button width="165px" buttonType="secondary" @click="buttonClick(2)"
          ><slot name="secondaryButton"
        /></Button>
      </div>
      <Button width="100%" @click="buttonClick(1)" v-else
        ><slot name="primaryButton"
      /></Button>

      <p class="footer" v-show="this.$slots.footer"><slot name="footer"></slot></p>
    </div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";

@Options({
  name: "Modal",
  emits: ["close", "buttonClick"],
  components: {
    Button,
  },
  props: {
    title: String,
    message: String,
    closeButton: {
      type: Boolean,
      default: false,
    },
  },
})
export default class Modal extends Vue {
  twoButtons!: boolean;

  isTwoButtons(): boolean {
    if (this.$slots.primaryButton && this.$slots.secondaryButton) {
      return true;
    } else {
      return false;
    }
  }

  close(): void {
    this.$emit("close");
  }

  buttonClick(button: number): void {
    this.$emit("buttonClick", button);
  }

  // Lifecycle hooks
  created(): void {
    this.twoButtons = this.isTwoButtons();
  }
  beforeUpdate(): void {
    this.twoButtons = this.isTwoButtons();
  }
}
</script>

<style scoped>
.modalBackground {
  background-color: rgba(0, 0, 0, 0.75);
  position: fixed;
  z-index: 100;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
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

.modalContent {
  margin-bottom: 25px;
  margin-top: 20px;
}

.message {
  color: var(--textSecondary);
  margin-top: 5px;
}

.footer {
  color: var(--textSecondary);
  font-size: 14px;
  margin-top: 15px;
}

.closeButton {
  position: absolute;
  top: 15px;
  right: 15px;
  height: 25px;
  width: 25px;
  cursor: pointer;
}

.closeButton > div {
  content: "";
  width: 2px;
  height: 25px;
  background-color: var(--backgroundTertiary);
  position: absolute;
  top: 0;
  left: 12px;
  border-radius: 1px;
}
.closeButton:hover > div {
  background-color: var(--textSecondary);
}
.closeButton > div:first-child {
  transform: rotate(45deg);
}
.closeButton > div:last-child {
  transform: rotate(-45deg);
}
</style>
