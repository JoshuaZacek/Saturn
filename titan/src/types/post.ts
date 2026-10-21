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
  // Pixel size of an image post (as displayed); null for text posts and for
  // older image posts whose size isn't known.
  image_width?: number | null
  image_height?: number | null
}

export interface PostsResponse {
  next_cursor: string | null
  posts: Post[]
}
