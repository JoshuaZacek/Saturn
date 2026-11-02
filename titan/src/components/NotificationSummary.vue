<script setup lang="ts">
import { computed } from 'vue'
import RelativeTime from '@/components/RelativeTime.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import UpvoteIcon from '@/components/icons/UpvoteIcon.vue'
import { notificationText, type AppNotification } from '@/utils/notifications'

// What a notification says, in the bell's list and in a pop-up: who (or an
// upvote arrow for a milestone), one sentence, the comment it's about and when.
const props = defineProps<{
  notification: AppNotification
}>()

const parts = computed(() => notificationText(props.notification))
const isMilestone = computed(
  () => props.notification.type === 'post_upvotes' || props.notification.type === 'comment_upvotes',
)
</script>

<template>
  <div class="notificationSummary">
    <span v-if="isMilestone" class="milestoneIcon">
      <UpvoteIcon :size="18" />
    </span>
    <UserAvatar
      v-else
      :name="notification.actor?.username ?? '?'"
      :color="notification.actor?.avatar_color"
      :image="notification.actor?.avatar_image"
      :size="36"
    />
    <div class="body">
      <p class="sentence">
        <template v-for="(part, index) in parts" :key="index">
          <strong v-if="part.strong">{{ part.text }}</strong>
          <template v-else>{{ part.text }}</template>
        </template>
      </p>
      <p v-if="notification.comment?.snippet" class="snippet">{{ notification.comment.snippet }}</p>
      <RelativeTime class="time" :datetime="notification.inserted_at" />
    </div>
  </div>
</template>

<style scoped>
.notificationSummary {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  min-width: 0;
}

.milestoneIcon {
  display: inline-grid;
  place-items: center;
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: var(--radius-full);
  background-color: color-mix(in srgb, var(--vote-up) 14%, transparent);
  color: var(--vote-up);
}

.body {
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
  min-width: 0;
}

.sentence {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  overflow: hidden;
  font-size: var(--text-subhead);
  line-height: 1.35;
  color: var(--text-1);
  overflow-wrap: anywhere;
}

.sentence strong {
  font-weight: 600;
}

.snippet {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  overflow: hidden;
  font-size: var(--text-subhead);
  line-height: 1.35;
  color: var(--text-2);
  overflow-wrap: anywhere;
}

.time {
  font-size: var(--text-footnote);
  color: var(--text-3);
}
</style>
