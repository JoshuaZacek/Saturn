<template>
  <button :class="[inModal ? 'modal' : '', buttonType]">
    <slot />
  </button>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  props: {
    buttonType: {
      type: String,
      default: "primary",
    },
    inModal: {
      type: Boolean,
      default: false,
    },
  },
})
export default class Button extends Vue {
  buttonType!: string;
  inModal!: boolean;
}
</script>

<style scoped>
button {
  border: none;
  cursor: pointer;
  font-weight: 600;
  font-size: 16px;
  padding: 9px 20px;
  border-radius: 15px;
}

button.modal {
  width: 100%;
}

button.primary {
  color: #fff;
  background-color: #006cff;
}
button.primary:hover {
  background-color: #005ff2;
}
button.primary:active {
  background-color: #0053e6;
}

button.secondary {
  color: #000;
  background-color: #efefef;
}
button.secondary:hover {
  background-color: #e2e2e2;
}
button.secondary:active {
  background-color: #d6d6d6;
}

button.destructive {
  color: #fff;
  background-color: #ff0000;
}
button.destructive:hover {
  background-color: #f20000;
}
button.destructive:active {
  background-color: #e60000;
}
</style>
