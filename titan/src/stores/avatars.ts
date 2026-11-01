import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { AvatarFields, AvatarKind } from '@/utils/avatar'

const keyOf = (kind: AvatarKind, name: string) => `${kind}:${name}`

// Pictures known by name, for the places that only have a name to go on (the
// sidebar's "Currently viewing" row), and pictures changed in this session,
// which every avatar of that person or moon shows straight away, instead of
// what was loaded before the change.
export const useAvatarStore = defineStore('avatars', () => {
  const known = ref<Record<string, AvatarFields>>({})
  const changed = ref<Record<string, AvatarFields>>({})

  const remember = (kind: AvatarKind, name: string, avatar: AvatarFields) => {
    const key = keyOf(kind, name)
    known.value[key] = changed.value[key] ?? {
      avatar_color: avatar.avatar_color,
      avatar_image: avatar.avatar_image,
    }
  }

  const change = (kind: AvatarKind, name: string, avatar: AvatarFields) => {
    const key = keyOf(kind, name)
    const fields = { avatar_color: avatar.avatar_color, avatar_image: avatar.avatar_image }
    known.value[key] = fields
    changed.value[key] = fields
  }

  const lookup = (kind: AvatarKind, name: string): AvatarFields | undefined =>
    known.value[keyOf(kind, name)]

  const changedFor = (kind: AvatarKind, name: string): AvatarFields | undefined =>
    changed.value[keyOf(kind, name)]

  return { remember, change, lookup, changedFor }
})
