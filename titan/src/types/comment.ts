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

// Comments listed on a profile also carry the post they were made on.
export interface ProfileComment extends Comment {
  post: {
    id: number
    title: string
  }
}
