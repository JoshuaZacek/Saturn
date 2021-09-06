<template>
  <div :style="setCSSVars" :class="$style.segmentedControl">
    <label v-for="(segment, index) in segments" :key="index">
      <input type="radio" name="segment" @change="moveSegment(index)" />
      {{ segment }}
      <span />
    </label>

    <div :class="$style.selectedBackground" ref="selectedBackground"></div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  name: "SegmentedControl",
  props: {
    segments: Array,
  },
  emits: ["change"],
})
export default class SegmentedControl extends Vue {
  segments!: Array<string>;
  declare $refs: {
    selectedBackground: HTMLDivElement;
  };

  moveSegment(index: number): void {
    const selectedBackground = this.$refs.selectedBackground;
    const segmentPosition = (550 / this.segments.length) * index;

    selectedBackground.style.transform = `translateX(${segmentPosition}px)`;

    this.$emit("change", this.segments[index]);
  }

  get setCSSVars(): string {
    return `--length: ${550 / this.segments.length}px`;
  }
}
</script>

<style scoped>
label {
  width: var(--length);
  height: 50px;
  display: inline-block;
  position: relative;
  z-index: 1;
  cursor: pointer;
  text-align: center;
  line-height: 50px;
}

label:not(:first-child) > span {
  border-right: 1px solid var(--backgroundTertiary);
  position: absolute;
  top: 15px;
  left: 0;
  height: 20px;
}

input {
  display: none;
}
</style>

<style module>
.segmentedControl {
  width: 550px;
  height: 50px;
  background-color: var(--backgroundSecondary);
  border-radius: 15px;
  position: relative;
  z-index: 0;
}

.selectedBackground {
  width: calc(var(--length) + 1px);
  height: 50px;
  display: inline-block;
  background-color: var(--backgroundTertiary);
  border-radius: 15px;
  position: absolute;
  top: 0;
  left: 0;
  z-index: 0;
  transition: transform 0.3s ease;
}
</style>
