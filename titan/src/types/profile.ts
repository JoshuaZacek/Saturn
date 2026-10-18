import type { ProfileComment } from '@/types/comment'
import type { Post } from '@/types/post'

export interface ProfileUser {
  id: number
  username: string
  inserted_at: string
}

export type ProfileContentType = 'overview' | 'posts' | 'comments'

// Entries of `GET /profile/overview` say what they are with `contentType`.
export type ProfileOverviewEntry =
  | (Post & { contentType: 'post' })
  | (ProfileComment & { contentType: 'comment' })

export type ProfileItem =
  | { kind: 'post'; post: Post }
  | { kind: 'comment'; comment: ProfileComment }

export interface ProfileContentResponse<T> {
  content: T[]
  next_cursor: string | null
}
