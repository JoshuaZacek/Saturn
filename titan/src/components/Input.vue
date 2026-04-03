<template>
  <div class="input-container">
    <input :class="{ error: error }" :type="type" :name="name" placeholder=" " />
    <label :class="{ error: error }" :for="name">{{ label }}</label>
    <p v-if="error">{{ error }}</p>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  name: "Input",
  props: {
    label: String,
    type: String,
    error: String,
  },
})
export default class Input extends Vue {
  label!: string;

  get name(): string {
    return this.label.toLowerCase().replace(/ /g, "");
  }
}
</script>

<style scoped>
p {
  background-color: #fff;
  color: #ff0000;
  font-size: 15px;
  margin-top: 5px;
}

div {
  position: relative;
  width: calc(100% - 30px);
}

input {
  width: 100%;
  outline: none;
  border-color: #dddddd;
  border-style: solid;
  border-width: 1px;
  border-radius: 15px;
  font-size: 19px;
  font-weight: bold;
  padding: 10px 15px;
  -webkit-appearance: none;
  background-color: white;
  color: black;
}
input[type="password"] {
  font-family: caption;
}
input.error {
  border-color: #ff0000;
}
input:not(:placeholder-shown):not(:focus).error + label {
  color: #ff0000;
}
input:focus {
  border-color: #006cff;
}
input:focus + label {
  color: #006cff;
  transform: scale(0.8) translateY(-12.5px) translateX(17.5px);
  padding: 0 5px;
}
input:not(:placeholder-shown) + label {
  transform: scale(0.8) translateY(-12.5px) translateX(17.5px);
  padding: 0 5px;
}
label {
  font-size: 19px;
  position: absolute;
  top: 0;
  left: 0;
  transform: translateY(11px) translateX(17.5px);
  transform-origin: 0%;
  color: #dddddd;
  background-color: white;
  pointer-events: none;
}
</style>
