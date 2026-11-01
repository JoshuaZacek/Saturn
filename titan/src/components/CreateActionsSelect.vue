<script setup lang="ts">
import ActionMenu, { type ActionMenuItem } from '@/components/ActionMenu.vue'
import CreatePostIcon from '@/components/icons/CreatePostIcon.vue'
import PlanetIcon from '@/components/icons/PlanetIcon.vue'
import PlusIcon from '@/components/icons/PlusIcon.vue'

// The Create (+) menu, in the sidebar and the phone top bar. The same menu as
// the account menu beside it on phones.
const createActions: ActionMenuItem[] = [
  { value: 'create-post', label: 'Create post', icon: CreatePostIcon, to: { name: 'create-post' } },
  { value: 'create-moon', label: 'Create moon', icon: PlanetIcon, to: { name: 'create-moon' } },
]
</script>

<template>
  <ActionMenu class="createMenu" label="Create" :items="createActions" size="lg">
    <template #trigger>
      <PlusIcon :size="24" />
    </template>
  </ActionMenu>
</template>
