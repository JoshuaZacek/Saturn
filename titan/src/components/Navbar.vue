<template>
  <div>
    <router-link to="/">Saturn</router-link>
    <span>
      <Button style="margin-right: 10px">Log in</Button>
      <Button buttonType="secondary">Sign up</Button>
    </span>
  </div>
</template>

<script>
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";

@Options({
  components: {
    Button,
  },
})
export default class Navbar extends Vue {}
</script>

<style scoped>
div {
  display: flex;
  justify-content: space-between;
  align-items: center;

  box-sizing: border-box;
  padding: 0 15px;
  width: 100%;
  height: 50px;

  position: sticky;
  top: 0px;

  background: var(--backgroundSecondary);
}

a {
  font-weight: bold;
  font-size: 19px;
  text-decoration: none;
  color: var(--textPrimary);
}
</style>
