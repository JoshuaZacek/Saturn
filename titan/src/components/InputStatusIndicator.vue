<script setup lang="ts">
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import CheckIcon from '@/components/icons/CheckIcon.vue'

// Sits after a text input: a spinner while the value is being checked, a
// check mark once it's valid. It grows in and out of the row, and the two
// icons cross-fade, so the input never jumps.
defineProps<{
  status: 'checking' | 'valid' | null
}>()
</script>

<template>
  <span class="inputStatusIndicator" :class="{ visible: status !== null }" aria-live="polite">
    <Transition name="indicatorIcon" mode="out-in">
      <SpinnerLoader
        v-if="status === 'checking'"
        key="spinner"
        :size="20"
        bgColor="var(--bg-sub)"
        fgColor="var(--text-3)"
      />
      <CheckIcon v-else-if="status === 'valid'" key="check" :size="20" color="var(--vote-up)" />
    </Transition>
  </span>
</template>

<style scoped>
.inputStatusIndicator {
  width: 0;
  opacity: 0;
  transform: scale(0.6);
  margin-left: 0;
  overflow: hidden;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  transition:
    width 0.2s ease,
    opacity 0.2s ease,
    transform 0.2s ease,
    margin-left 0.2s ease;
}

.inputStatusIndicator.visible {
  width: 20px;
  opacity: 1;
  transform: scale(1);
  margin-left: 0.5rem;
}

.indicatorIcon-enter-active,
.indicatorIcon-leave-active {
  transition:
    opacity 0.15s ease,
    transform 0.15s ease;
}

.indicatorIcon-enter-from,
.indicatorIcon-leave-to {
  opacity: 0;
  transform: scale(0.5);
}
</style>
