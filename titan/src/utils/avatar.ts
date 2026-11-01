// The colours a monogram can be. The API stores the name; each is a hue, which
// App.vue's --avatar-* tokens turn into a soft tint for light and dark mode.
export const AVATAR_COLORS = [
  { name: 'red', label: 'Red', hue: 8 },
  { name: 'orange', label: 'Orange', hue: 24 },
  { name: 'amber', label: 'Amber', hue: 40 },
  { name: 'lime', label: 'Lime', hue: 88 },
  { name: 'green', label: 'Green', hue: 142 },
  { name: 'teal', label: 'Teal', hue: 168 },
  { name: 'cyan', label: 'Cyan', hue: 190 },
  { name: 'sky', label: 'Sky', hue: 210 },
  { name: 'blue', label: 'Blue', hue: 232 },
  { name: 'indigo', label: 'Indigo', hue: 258 },
  { name: 'purple', label: 'Purple', hue: 288 },
  { name: 'pink', label: 'Pink', hue: 330 },
] as const

export type AvatarColor = (typeof AVATAR_COLORS)[number]['name']

// People are circles and moons are rounded tiles.
export type AvatarKind = 'user' | 'moon'

// How the API describes a person's or moon's picture.
export interface AvatarFields {
  avatar_color: string
  avatar_image: string | null
}

export const avatarHue = (color: string | null | undefined) =>
  AVATAR_COLORS.find((option) => option.name === color)?.hue ?? null

// The first letter or digit of a name, for its monogram.
export const avatarInitial = (name: string) =>
  (name.match(/[\p{L}\p{N}]/u)?.[0] ?? '?').toUpperCase()

const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined

// Uploaded files are served (via a redirect to storage) from /assets.
export const assetUrl = (filename: string) =>
  `${(backendUrl ?? '').replace(/\/$/, '')}/assets/${encodeURIComponent(filename)}`
