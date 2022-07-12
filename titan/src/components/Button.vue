<template>
  <button :class="[color, size]">
    <slot />
  </button>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  name: "Button",
  props: {
    color: {
      type: String,
      default: "blue",
    },
    size: {
      type: String,
      default: "large",
    },
  },
})
export default class Button extends Vue {}
</script>

<style scoped>
/* Base */
button {
  display: inline-block;

  border: none;
  cursor: pointer;

  font-weight: 500;
  font-size: 16px;

  background-color: transparent;
}

/* Sizes */
button.large {
  padding: 10px 15px;
  border-radius: 15px;
}
button.small {
  padding: 5px 10px;
  border-radius: 12px;
}

/* colors */
button.blue {
  color: #006cff;
}
button.blue:hover,
button.blue.large {
  background-color: #006cff11;
}

button.red {
  color: #ff0000;
}
button.red:hover,
button.red.large {
  background-color: #ff000011;
}
</style>
