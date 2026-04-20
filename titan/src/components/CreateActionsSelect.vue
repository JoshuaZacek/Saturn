<script setup lang="ts">
import { ref, type Component } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import CustomSelect from '@/components/CustomSelect.vue'
import PlusIcon from '@/components/icons/PlusIcon.vue'
import CreatePostIcon from '@/components/icons/CreatePostIcon.vue'

const selectedAction = ref<string | undefined>(undefined)

const createOptions: Array<{
  label: string
  value: string
  to: RouteLocationRaw
  icon?: Component
}> = [
  {
    label: 'Create post...',
    value: 'create-post',
    to: { name: 'create-post' },
    icon: CreatePostIcon,
  },
  {
    label: 'Create moon...',
    value: 'create-moon',
    to: { name: 'create-moon' },
  },
]
</script>

<template>
  <CustomSelect
    v-model="selectedAction"
    :options="createOptions"
    label="Create"
    placeholder="Create"
    :trigger-icon="PlusIcon"
    :focus-menu-on-open="false"
  />
</template>
