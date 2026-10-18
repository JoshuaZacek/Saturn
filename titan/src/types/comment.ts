export interface CommentUser {
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
  user: CommentUser
}

export interface CommentsResponse {
  comments: Comment[]
  next_cursor: string | null
}
