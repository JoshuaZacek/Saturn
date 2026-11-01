import type { AvatarFields } from '@/utils/avatar'

export interface CommentUser extends AvatarFields {
  id: number
  username: string
  inserted_at: string
}

export interface Comment {
  id: number
  content: string
  votes: number
  hasVoted: number | null
  replies: number | boolean | null
  inserted_at: string
  updated_at: string
  // When its author last changed its text, if they have.
  edited_at: string | null
  // Deleted while it had replies: kept in its thread with no text and no author.
  deleted: boolean
  user: CommentUser | null
}

export interface CommentsResponse {
  comments: Comment[]
  next_cursor: string | null
}

// Comments listed on a profile also carry the post they were made on.
export interface ProfileComment extends Comment {
  post: {
    id: number
    title: string
  }
}
