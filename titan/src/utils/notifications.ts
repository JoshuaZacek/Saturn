import type { RouteLocationRaw } from 'vue-router'
import { formatCompactCount } from '@/utils/formatCount'

// How the API describes a notification (GET /notifications, and the websocket).
export type NotificationType = 'post_comment' | 'comment_reply' | 'post_upvotes' | 'comment_upvotes'

export interface AppNotification {
  id: number
  type: NotificationType
  // The upvote milestone reached, for *_upvotes
  count: number | null
  read: boolean
  inserted_at: string
  post: { id: number; title: string }
  // The new comment (post_comment, comment_reply) or the upvoted one (comment_upvotes)
  comment: { id: number; snippet: string } | null
  // Who commented; null for milestones, or once they've deleted their account
  actor: {
    id: number
    username: string
    avatar_color: string | null
    avatar_image: string | null
  } | null
}

// One sentence, in parts, so the names in it can be bold.
export type NotificationText = { text: string; strong?: boolean }[]

const upvotes = (count: number | null) =>
  count === 1 ? '1 upvote' : `${formatCompactCount(count ?? 0)} upvotes`

export const notificationText = (notification: AppNotification): NotificationText => {
  const actor = notification.actor?.username ?? 'Someone'
  const title = `“${notification.post.title}”`

  switch (notification.type) {
    case 'post_comment':
      return [{ text: actor, strong: true }, { text: ` commented on ${title}` }]
    case 'comment_reply':
      return [{ text: actor, strong: true }, { text: ` replied to your comment on ${title}` }]
    case 'post_upvotes':
      return [
        { text: `Your post ${title} reached ` },
        { text: upvotes(notification.count), strong: true },
      ]
    case 'comment_upvotes':
      return [
        { text: `Your comment on ${title} reached ` },
        { text: upvotes(notification.count), strong: true },
      ]
  }
}

// The same sentence as plain text, for labels and screen readers.
export const notificationLabel = (notification: AppNotification) =>
  notificationText(notification)
    .map((part) => part.text)
    .join('')

// Where it leads: the comment it's about, or the post.
export const notificationRoute = (notification: AppNotification): RouteLocationRaw => ({
  name: 'post',
  params: {
    post_id: String(notification.post.id),
    comment_id: notification.comment ? String(notification.comment.id) : undefined,
  },
})
