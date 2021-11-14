<template>
  <div class="wrapper">
    <div
      class="tooltipButton"
      @mouseover="showTooltip = true"
      @mouseout="showTooltip = false"
    >
      ?
    </div>
    <div v-show="showTooltip" class="tooltipText"><slot /></div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  name: "Tooltip",
})
export default class Home extends Vue {
  showTooltip = false;
}
</script>

<style scoped>
.wrapper {
  position: relative;
}
.tooltipButton {
  background-color: var(--backgroundTertiary);
  border-radius: 100%;
  width: 20px;
  height: 20px;
  text-align: center;
  font-weight: 500;
  cursor: help;
  position: absolute;
  right: 0;
}
.tooltipText {
  position: relative;
  top: 30px;
  padding: 10px 15px;
  border-radius: 15px;
  background-color: var(--backgroundTertiary);
  max-width: 200px;
}
</style>
