<template>
  <div class="loader" :style="cssProps">
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  name: "Loader",
  props: {
    size: Number,
    bgColor: String,
    fgColor: String,
  },
})
export default class Input extends Vue {
  size!: number;
  bgColor!: string;
  fgColor!: string;

  get cssProps(): Record<string, string> {
    return {
      "--size": this.size + "px",
      "--center": Math.round(this.size / 2) + "px",
      "--left": Math.round((this.size / 2) * 0.925) + "px",
      "--width": Math.round((this.size / 2) * 0.15) + "px",
      "--height": Math.floor((this.size / 2) * 0.6) + "px",
      "--fgColor": this.fgColor,
      "--bgColor": this.bgColor,
    };
  }
}
</script>

<style scoped>
.loader {
  background-color: var(--bgColor);
  position: relative;
  width: var(--size);
  height: var(--size);
}

.loader div {
  transform-origin: var(--center) var(--center);
  animation: loader 1.2s linear infinite;
}

.loader div:after {
  content: "";
  display: block;
  position: absolute;
  top: 0px;
  left: var(--left);
  width: var(--width);
  height: var(--height);
  border-radius: 200px;
  background: var(--fgColor);
}
.loader div:nth-child(1) {
  transform: rotate(0deg);
  animation-delay: -1.1s;
}
.loader div:nth-child(2) {
  transform: rotate(30deg);
  animation-delay: -1s;
}
.loader div:nth-child(3) {
  transform: rotate(60deg);
  animation-delay: -0.9s;
}
.loader div:nth-child(4) {
  transform: rotate(90deg);
  animation-delay: -0.8s;
}
.loader div:nth-child(5) {
  transform: rotate(120deg);
  animation-delay: -0.7s;
}
.loader div:nth-child(6) {
  transform: rotate(150deg);
  animation-delay: -0.6s;
}
.loader div:nth-child(7) {
  transform: rotate(180deg);
  animation-delay: -0.5s;
}
.loader div:nth-child(8) {
  transform: rotate(210deg);
  animation-delay: -0.4s;
}
.loader div:nth-child(9) {
  transform: rotate(240deg);
  animation-delay: -0.3s;
}
.loader div:nth-child(10) {
  transform: rotate(270deg);
  animation-delay: -0.2s;
}
.loader div:nth-child(11) {
  transform: rotate(300deg);
  animation-delay: -0.1s;
}
.loader div:nth-child(12) {
  transform: rotate(330deg);
  animation-delay: 0s;
}
@keyframes loader {
  0% {
    opacity: 1;
  }
  100% {
    opacity: 0;
  }
}
</style>
