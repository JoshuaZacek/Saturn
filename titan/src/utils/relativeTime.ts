export const formatRelativeTime = (dateString: string) => {
  const date = new Date(dateString)
  const now = Date.now()

  if (Number.isNaN(date.getTime())) {
    return ''
  }

  const diffSeconds = Math.max(1, Math.floor((now - date.getTime()) / 1000))

  if (diffSeconds < 60) {
    return `${diffSeconds}s ago`
  }

  const diffMinutes = Math.floor(diffSeconds / 60)
  if (diffMinutes < 60) {
    return `${diffMinutes}m ago`
  }

  const diffHours = Math.floor(diffMinutes / 60)
  if (diffHours < 24) {
    return `${diffHours}h ago`
  }

  const diffDays = Math.floor(diffHours / 24)
  if (diffDays < 30) {
    return `${diffDays}d ago`
  }

  const diffMonths = Math.floor(diffDays / 30)
  if (diffMonths < 12) {
    return `${diffMonths}mo ago`
  }

  const diffYears = Math.floor(diffDays / 365)
  return `${diffYears}y ago`
}
