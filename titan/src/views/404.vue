<template>
  <div>
    <h3>Content does not exist</h3>
    <p>
      The content you requested may have been modified, deleted, or may have a different
      spelling.
    </p>

    <Button @click="$router.push({ name: 'Home' })" size="small"
      >Go to the front page</Button
    >
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import Button from "@/components/Button.vue";

@Options({
  components: {
    Button,
  },
})
export default class NotFund extends Vue {}
</script>

<style scoped>
div {
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  gap: 5px;

  position: absolute;
  top: calc(50% + 25px);
  transform: translateY(-50%);
}

h3 {
  color: var(--textPrimary);
}

p {
  color: var(--textSecondary);
  max-width: 60%;
  text-align: center;
}
</style>
