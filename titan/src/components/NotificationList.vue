<script setup lang="ts">
import EmptyState from '@/components/EmptyState.vue'
import ErrorBanner from '@/components/ErrorBanner.vue'
import NotificationSummary from '@/components/NotificationSummary.vue'
import SpinnerLoader from '@/components/SpinnerLoader.vue'
import SubmitButton from '@/components/SubmitButton.vue'
import BellIcon from '@/components/icons/BellIcon.vue'
import CheckIcon from '@/components/icons/CheckIcon.vue'
import CloseIcon from '@/components/icons/CloseIcon.vue'
import { useNotificationsStore } from '@/stores/notifications'
import { notificationRoute, type AppNotification } from '@/utils/notifications'

// The bell's list, in its popover (desktop) or sheet (phones). Choosing one
// goes to it; the parent closes itself on `navigate`.
const emit = defineEmits<{
  navigate: []
}>()

const notifications = useNotificationsStore()

// Opening one reads it.
const open = (notification: AppNotification) => {
  if (!notification.read) {
    void notifications.markRead([notification.id])
  }

  emit('navigate')
}
</script>

<template>
  <div class="notificationList">
    <ErrorBanner
      v-if="notifications.actionError"
      class="listError"
      :message="notifications.actionError"
      @dismiss="notifications.dismissActionError()"
    />

    <div v-if="notifications.status === 'error'" class="state">
      <EmptyState
        title="Notifications couldn't be loaded"
        description="Check your connection and try again."
      >
        <SubmitButton variant="secondary" size="sm" @click="notifications.fetch()">
          Try again
        </SubmitButton>
      </EmptyState>
    </div>

    <div
      v-else-if="notifications.items.length === 0 && notifications.status !== 'ready'"
      class="state"
    >
      <SpinnerLoader :size="24" bg-color="transparent" fg-color="var(--text-2)" />
    </div>

    <div v-else-if="notifications.items.length === 0" class="state">
      <EmptyState
        :icon="BellIcon"
        title="No notifications yet"
        description="Comments on your posts, replies to your comments and upvotes will show up here."
      />
    </div>

    <template v-else>
      <ul class="items">
        <li
          v-for="notification in notifications.items"
          :key="notification.id"
          class="row"
          :class="{ unread: !notification.read }"
        >
          <RouterLink
            class="item"
            :to="notificationRoute(notification)"
            @click="open(notification)"
          >
            <NotificationSummary :notification="notification" />
            <span v-if="!notification.read" class="visually-hidden">(new)</span>
          </RouterLink>
          <div class="rowActions">
            <button
              v-if="!notification.read"
              class="rowAction markRead"
              type="button"
              aria-label="Mark as read"
              title="Mark as read"
              @click="notifications.markRead([notification.id])"
            >
              <span class="dot" aria-hidden="true" />
              <CheckIcon class="check" :size="16" />
            </button>
            <button
              v-else
              class="rowAction markUnread"
              type="button"
              aria-label="Mark as unread"
              title="Mark as unread"
              @click="notifications.markUnread(notification.id)"
            >
              <span class="ring" aria-hidden="true" />
            </button>
            <button
              class="rowAction remove"
              type="button"
              aria-label="Remove notification"
              title="Remove"
              @click="notifications.remove(notification.id)"
            >
              <CloseIcon :size="16" />
            </button>
          </div>
        </li>
      </ul>
      <div v-if="notifications.hasMore" class="more">
        <SubmitButton
          variant="secondary"
          size="sm"
          :loading="notifications.isLoadingMore"
          @click="notifications.loadMore()"
        >
          Show older
        </SubmitButton>
      </div>
    </template>
  </div>
</template>

<style scoped>
.state {
  display: grid;
  place-items: center;
  min-height: 12rem;
}

.items {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.listError {
  margin-bottom: 0.5rem;
}

.row {
  position: relative;
}

.item {
  display: flex;
  align-items: flex-start;
  padding: 0.65rem 2.5rem 0.65rem 0.65rem;
  border-radius: var(--radius-md);
  color: inherit;
  text-decoration: none;
  transition: background-color var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .row:hover .item {
    background-color: var(--fill-hover);
  }
}

.item:active {
  background-color: var(--fill-pressed);
}

.item:focus-visible {
  outline: none;
  box-shadow: var(--focus-ring);
}

/* Down the right edge: the unread dot (which marks it read), or an empty one
   (which marks it unread), and remove. */
.rowActions {
  position: absolute;
  top: 0.4rem;
  right: 0.35rem;
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
}

.rowAction {
  display: inline-grid;
  place-items: center;
  width: 1.75rem;
  height: 1.75rem;
  padding: 0;
  border: none;
  border-radius: var(--radius-full);
  background: none;
  color: var(--text-2);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    opacity var(--duration-fast) var(--ease-out);
}

.rowAction:active {
  background-color: var(--fill-pressed);
}

.rowAction:focus-visible {
  outline: none;
  box-shadow: var(--focus-ring);
}

.dot {
  grid-area: 1 / 1;
  width: 0.5rem;
  height: 0.5rem;
  border-radius: var(--radius-full);
  background-color: var(--accent-color);
  transition: opacity var(--duration-fast) var(--ease-out);
}

.check {
  grid-area: 1 / 1;
  opacity: 0;
  transition: opacity var(--duration-fast) var(--ease-out);
}

.markRead:focus-visible .dot {
  opacity: 0;
}

.markRead:focus-visible .check {
  opacity: 1;
}

/* An empty dot: pressing it fills it in again. */
.ring {
  width: 0.5rem;
  height: 0.5rem;
  border: 1.5px solid var(--text-3);
  border-radius: var(--radius-full);
  transition: border-color var(--duration-fast) var(--ease-out);
}

.markUnread:focus-visible .ring {
  border-color: var(--accent-color);
}

@media (hover: hover) {
  .rowAction:hover {
    background-color: var(--fill-hover);
    color: var(--text-1);
  }

  /* The dot turns into a tick to say what pressing it does. */
  .markRead:hover .dot {
    opacity: 0;
  }

  .markRead:hover .check {
    opacity: 1;
  }

  .markUnread:hover .ring {
    border-color: var(--accent-color);
  }

  /* Remove and mark as unread show on the row being pointed at (or focused
     into), so a list of them doesn't look like a list of buttons. */
  .remove,
  .markUnread {
    opacity: 0;
  }

  .row:hover .remove,
  .row:focus-within .remove,
  .row:hover .markUnread,
  .row:focus-within .markUnread {
    opacity: 1;
  }
}

.more {
  display: flex;
  justify-content: center;
  padding: 0.5rem 0 0.25rem;
}
</style>
