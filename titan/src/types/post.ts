export interface PostUser {
  id: number
  username: string
  inserted_at: string
}

export interface PostMoon {
  id: number
  name: string
  inserted_at: string
}

export interface Post {
  id: number
  type: string
  user: PostUser
  title: string
  body: string | null
  comments: number
  inserted_at: string
  votes: number
  hasVoted: number | null
  moon: PostMoon
  updated_at: string
}

export interface PostsResponse {
  next_cursor: string | null
  posts: Post[]
}
