<script setup lang="ts">
import { computed } from 'vue'
import ActionMenu, { type ActionMenuItem } from '@/components/ActionMenu.vue'
import CheckIcon from '@/components/icons/CheckIcon.vue'
import DeleteIcon from '@/components/icons/DeleteIcon.vue'
import { useNotificationsStore } from '@/stores/notifications'

// The ⋯ beside the list's title: mark everything read, or clear the list.
const notifications = useNotificationsStore()

const actions = computed<ActionMenuItem[]>(() => [
  ...(notifications.unreadCount > 0
    ? [{ value: 'read', label: 'Mark all as read', icon: CheckIcon }]
    : []),
  {
    value: 'clear',
    label: 'Clear all',
    icon: DeleteIcon,
    danger: true,
    confirm: {
      title: 'Clear all notifications?',
      message: 'They’ll be removed from this list.',
      action: 'Clear all',
    },
  },
])

const onSelect = (action: string) => {
  if (action === 'read') {
    void notifications.markRead()
  } else if (action === 'clear') {
    void notifications.clearAll()
  }
}
</script>

<template>
  <ActionMenu
    v-if="notifications.items.length > 0"
    label="Notification options"
    :items="actions"
    :busy="notifications.isClearing"
    @select="onSelect"
  />
</template>
