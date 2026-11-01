<script setup lang="ts">
import UserAvatar from '@/components/UserAvatar.vue'

// The header of a moon or a person: their monogram, name, one line about them
// (the `meta` slot) and what you can do (the `actions` slot).
defineProps<{
  name: string
  title: string
  kind: 'moon' | 'user'
}>()
</script>

<template>
  <header class="entityHeader">
    <UserAvatar
      class="entityAvatar"
      :name="name"
      :shape="kind === 'moon' ? 'tile' : 'circle'"
      :size="64"
    />
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
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 1rem 1.1rem;
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
    gap: 0.9rem;
  }

  .entityHeader .entityAvatar {
    width: 56px;
    height: 56px;
    font-size: 1.6rem;
  }

  .entityActions {
    flex-basis: 100%;
  }
}
</style>
