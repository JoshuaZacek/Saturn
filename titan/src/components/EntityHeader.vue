<script setup lang="ts">
import { computed } from 'vue'
import UserAvatar from '@/components/UserAvatar.vue'
import CameraIcon from '@/components/icons/CameraIcon.vue'
import type { AvatarFields } from '@/utils/avatar'

// The header of a moon or a person: their picture, name, one line about them
// (the `meta` slot) and what you can do (the `actions` slot). When the picture
// is yours to change, it's a button: hovering shows that it can be changed
// (touch screens, which can't hover, show a small badge instead).
const props = defineProps<{
  name: string
  title: string
  kind: 'moon' | 'user'
  // Null while loading: a neutral monogram.
  avatar?: AvatarFields | null
  editable?: boolean
}>()

const emit = defineEmits<{
  editAvatar: []
}>()

const shape = computed(() => (props.kind === 'moon' ? 'tile' : 'circle'))
const editLabel = computed(() =>
  props.kind === 'moon' ? 'Change the moon’s picture' : 'Change your profile picture',
)
</script>

<template>
  <header class="entityHeader">
    <button
      v-if="editable"
      class="avatarSlot avatarButton"
      :class="shape"
      type="button"
      :aria-label="editLabel"
      :title="editLabel"
      @click="emit('editAvatar')"
    >
      <UserAvatar
        class="entityAvatar"
        :name="name"
        :color="avatar?.avatar_color"
        :image="avatar?.avatar_image"
        :shape="shape"
        :size="64"
      />
      <span class="editScrim" aria-hidden="true"><CameraIcon :size="24" /></span>
      <span class="editBadge" aria-hidden="true"><CameraIcon :size="13" /></span>
    </button>
    <span v-else class="avatarSlot">
      <UserAvatar
        class="entityAvatar"
        :name="name"
        :color="avatar?.avatar_color"
        :image="avatar?.avatar_image"
        :shape="shape"
        :size="64"
      />
    </span>

    <div class="entityText">
      <h1 class="entityTitle">{{ title }}</h1>
      <div v-if="$slots.meta" class="entityMeta">
        <slot name="meta" />
      </div>
    </div>
    <div v-if="$slots.actions" class="entityActions">
      <slot name="actions" />
    </div>
  </header>
</template>

<style scoped>
.entityHeader {
  --entity-avatar: 64px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 1rem 1.1rem;
}

.avatarSlot {
  position: relative;
  display: inline-flex;
  flex-shrink: 0;
  border-radius: var(--radius-full);
}

.avatarSlot.tile {
  border-radius: calc(var(--entity-avatar) * 0.28);
}

/* Over the avatar's own inline size, so its corners and letter follow the
   smaller size on phones too. */
.entityAvatar {
  --avatar-size: var(--entity-avatar) !important;
}

.avatarButton {
  padding: 0;
  border: none;
  background: none;
  cursor: pointer;
  transition: transform var(--duration-fast) var(--ease-out);
}

.avatarButton:active {
  transform: scale(0.97);
}

/* Over the picture on hover: a dimmed layer with a camera. */
.editScrim {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  border-radius: inherit;
  background-color: rgb(0 0 0 / 38%);
  color: #ffffff;
  opacity: 0;
  transition: opacity var(--duration-fast) var(--ease-out);
}

@media (hover: hover) {
  .avatarButton:hover .editScrim {
    opacity: 1;
  }

  /* The camera replaces a monogram's letter rather than sitting on it. */
  .avatarButton:hover .entityAvatar {
    color: transparent;
  }
}

.avatarButton:focus-visible .editScrim {
  opacity: 1;
}

.avatarButton:focus-visible .entityAvatar {
  color: transparent;
}

/* Touch screens: a small camera badge on the corner, always shown. */
.editBadge {
  position: absolute;
  right: -2px;
  bottom: -2px;
  display: none;
  place-items: center;
  width: 1.5rem;
  height: 1.5rem;
  border-radius: var(--radius-full);
  background-color: var(--surface-raised);
  box-shadow:
    0 0 0 2px var(--bg-1),
    var(--shadow-md);
  color: var(--text-1);
}

@media (hover: none) {
  .editBadge {
    display: grid;
  }
}

.entityText {
  flex: 1;
  min-width: 0;
}

.entityTitle {
  overflow-wrap: anywhere;
}

/* One fact per line, so the header looks the same whatever the name's length. */
.entityMeta {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.1rem;
  min-height: 1.4em;
  margin-top: 0.25rem;
  font-size: var(--text-subhead);
  color: var(--text-2);
}

.entityActions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

/* Phones: the actions get their own row, under the name. */
@media (max-width: 600px) {
  .entityHeader {
    --entity-avatar: 56px;
    gap: 0.9rem;
  }

  .entityActions {
    flex-basis: 100%;
  }
}
</style>
