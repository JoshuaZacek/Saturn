<template>
  <div class="segmentedControl" ref="container">
    <label v-for="(segment, index) in segments" :key="index">
      <input type="radio" name="segment" @change="moveSegment(index)" />
      {{ segment }}
      <span />
    </label>

    <div class="selectedBackground" ref="selectedBackground"></div>
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
  width = 0;

  declare $refs: {
    selectedBackground: HTMLDivElement;
    container: Element;
  };

  mounted(): void {
    this.resize();

    window.addEventListener("resize", this.resize);
  }

  beforeUnmount(): void {
    window.removeEventListener("resize", this.resize);
  }

  resize(): void {
    this.width = parseInt(getComputedStyle(this.$refs.container).width.slice(0, -2));

    this.$refs.selectedBackground.style.width = `${this.width / this.segments.length +
      1}px`;
    this.$refs.container.querySelectorAll("label").forEach((label) => {
      label.style.width = `${this.width / this.segments.length}px`;
    });
  }

  moveSegment(index: number): void {
    const selectedBackground = this.$refs.selectedBackground;
    const segmentPosition = (this.width / this.segments.length) * index;

    selectedBackground.style.transform = `translateX(${segmentPosition}px)`;

    this.$emit("change", this.segments[index]);
  }
}
</script>

<style scoped>
.segmentedControl {
  width: 100%;
  height: 50px;
  margin-top: 30px;
  background-color: var(--backgroundSecondary);
  border-radius: 15px;
  position: relative;
  z-index: 0;
}

.selectedBackground {
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

label {
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
