<script setup lang="ts">
import { computed, ref, watch } from 'vue'

const props = withDefaults(
  defineProps<{
    filled: boolean
    direction: 'up' | 'down'
    size?: number
  }>(),
  {
    size: 22,
  },
)

const pathData = computed(() => {
  if (props.direction === 'up') {
    return props.filled
      ? 'M231.39,123.06A8,8,0,0,1,224,128H184v80a16,16,0,0,1-16,16H88a16,16,0,0,1-16-16V128H32a8,8,0,0,1-5.66-13.66l96-96a8,8,0,0,1,11.32,0l96,96A8,8,0,0,1,231.39,123.06Z'
      : 'M229.66,114.34l-96-96a8,8,0,0,0-11.32,0l-96,96A8,8,0,0,0,32,128H72v80a16,16,0,0,0,16,16h80a16,16,0,0,0,16-16V128h40a8,8,0,0,0,5.66-13.66ZM176,112a8,8,0,0,0-8,8v88H88V120a8,8,0,0,0-8-8H51.31L128,35.31,204.69,112Z'
  }

  return props.filled
    ? 'M229.66,141.66l-96,96a8,8,0,0,1-11.32,0l-96-96A8,8,0,0,1,32,128H72V48A16,16,0,0,1,88,32h80a16,16,0,0,1,16,16v80h40a8,8,0,0,1,5.66,13.66Z'
    : 'M231.39,132.94A8,8,0,0,0,224,128H184V48a16,16,0,0,0-16-16H88A16,16,0,0,0,72,48v80H32a8,8,0,0,0-5.66,13.66l96,96a8,8,0,0,0,11.32,0l96-96A8,8,0,0,0,231.39,132.94ZM128,220.69,51.31,144H80a8,8,0,0,0,8-8V48h80v88a8,8,0,0,0,8,8h28.69Z'
})

// Only a vote cast here pops, not one that was already there on load.
const popping = ref(false)
watch(
  () => props.filled,
  (filled) => {
    popping.value = filled
  },
)
</script>

<template>
  <button
    type="button"
    class="voteArrow"
    :class="direction"
    :aria-label="direction === 'up' ? 'Upvote' : 'Downvote'"
    :aria-pressed="filled"
    @click="$emit('vote')"
  >
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 256 256"
      :width="props.size"
      :height="props.size"
      aria-hidden="true"
      :class="{ filled, popping }"
      @animationend="popping = false"
    >
      <path :d="pathData" />
    </svg>
  </button>
</template>

<style scoped>
/* A round hit area (sized by VoteButtons through --vote-hit) around the arrow. */
.voteArrow {
  --vote-color: var(--vote-up);
  display: inline-grid;
  place-items: center;
  width: var(--vote-hit, 1.75rem);
  height: var(--vote-hit, 1.75rem);
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  color: var(--text-2);
  cursor: pointer;
  transition:
    color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.voteArrow.down {
  --vote-color: var(--vote-down);
}

@media (hover: hover) {
  .voteArrow:hover {
    color: var(--vote-color);
    background-color: color-mix(in srgb, var(--vote-color) 12%, transparent);
  }
}

.voteArrow:active {
  background-color: color-mix(in srgb, var(--vote-color) 20%, transparent);
}

svg {
  fill: currentColor;
}

svg.filled {
  fill: var(--vote-color);
}

svg.popping {
  animation: vote-pop var(--duration-base) var(--ease-out);
}

@media (prefers-reduced-motion: reduce) {
  svg.popping {
    animation: none;
  }
}

/* A short bump when a vote lands. */
@keyframes vote-pop {
  50% {
    transform: scale(1.18);
  }
}
</style>
