<script setup lang="ts">
import { computed, type Component } from 'vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'

const props = withDefaults(
  defineProps<{
    type?: 'button' | 'submit' | 'reset'
    disabled?: boolean
    variant?: 'default' | 'secondary' | 'danger'
    // An icon component (taking `size`) shown before the label, in the label's colour.
    icon?: Component
    // Full width: the main action at the end of a sheet or narrow form.
    block?: boolean
    // sm: toolbars and inline actions; md: most buttons; lg: the end of a form.
    size?: 'sm' | 'md' | 'lg'
    // Swaps the label for a spinner without changing the button's size.
    loading?: boolean
  }>(),
  {
    type: 'button',
    variant: 'default',
    size: 'md',
    icon: undefined,
  },
)

const spinnerColors = computed(() => {
  switch (props.variant) {
    case 'secondary':
      return { bg: 'var(--fill-secondary)', fg: 'var(--text-2)' }
    case 'danger':
      return { bg: 'var(--danger-fill)', fg: '#ffffff' }
    default:
      return { bg: 'var(--accent-fill)', fg: 'var(--accent-text)' }
  }
})
</script>

<template>
  <button
    class="submitButton"
    :class="[variant, size, { withIcon: icon, block, loading }]"
    :type="type"
    :disabled="disabled || loading"
    :aria-busy="loading || undefined"
  >
    <span class="content">
      <component :is="icon" v-if="icon" class="buttonIcon" :size="size === 'sm' ? 16 : 18" />
      <slot />
    </span>
    <span v-if="loading" class="spinner" aria-hidden="true">
      <SpinnerLoader :size="18" :bg-color="spinnerColors.bg" :fg-color="spinnerColors.fg" />
    </span>
  </button>
</template>

<style scoped>
.submitButton {
  display: inline-grid;
  place-items: center;
  height: var(--control-md);
  padding: 0 0.95rem;
  border: none;
  border-radius: var(--radius-md);
  background-color: var(--accent-fill);
  color: var(--accent-text);
  font-size: var(--text-body);
  font-weight: 500;
  white-space: nowrap;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

/* The label and the spinner share one cell, so the width never changes. */
.content,
.spinner {
  grid-area: 1 / 1;
}

.content {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}

.spinner {
  display: inline-flex;
}

.loading .content {
  visibility: hidden;
}

.submitButton.withIcon {
  padding-left: 0.75rem;
}

.submitButton.sm {
  height: var(--control-sm);
  padding: 0 0.75rem;
  font-size: var(--text-subhead);
}

.submitButton.sm.withIcon {
  padding-left: 0.6rem;
}

.submitButton.lg {
  height: var(--control-lg);
  padding: 0 1.25rem;
  font-weight: 600;
}

.submitButton.block {
  width: 100%;
}

.submitButton.secondary {
  background-color: var(--fill-secondary);
  color: var(--text-1);
}

.submitButton.danger {
  background-color: var(--danger-fill);
  color: #ffffff;
}

@media (hover: hover) {
  .submitButton:hover:not(:disabled) {
    background-color: var(--accent-fill-hover);
  }

  .submitButton.secondary:hover:not(:disabled) {
    background-color: var(--fill-secondary-hover);
  }

  .submitButton.danger:hover:not(:disabled) {
    background-color: color-mix(in srgb, var(--danger-fill) 90%, #000);
  }
}

.submitButton:active:not(:disabled) {
  background-color: var(--accent-fill-pressed);
  transform: scale(0.98);
}

.submitButton.secondary:active:not(:disabled) {
  background-color: var(--fill-secondary-hover);
}

.submitButton.danger:active:not(:disabled) {
  background-color: color-mix(in srgb, var(--danger-fill) 82%, #000);
}

.submitButton:disabled {
  cursor: default;
}

.submitButton:disabled:not(.loading) {
  opacity: 0.5;
}
</style>
