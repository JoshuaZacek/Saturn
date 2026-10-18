import type { LocationQueryValue } from 'vue-router'

export type FeedSort = 'new' | 'top'

export const getSingleQueryValue = (
  value: LocationQueryValue | LocationQueryValue[] | undefined,
) => (Array.isArray(value) ? value[0] : value)

// `t` query values → `time_period` seconds for `GET /posts` (0 = all time).
export const getTimePeriod = (value: unknown) => {
  switch (value) {
    case 'day':
      return 86400
    case 'week':
      return 604800
    case 'month':
      return 2592000
    case 'year':
      return 31536000
    default:
      return 0
  }
}

export const timePeriodOptions = [
  { label: 'Today', value: 'day' },
  { label: 'This Week', value: 'week' },
  { label: 'This Month', value: 'month' },
  { label: 'This Year', value: 'year' },
  { label: 'All Time', value: 'all' },
]

export const sortOptions: Array<{ label: string; value: FeedSort }> = [
  { label: 'Top', value: 'top' },
  { label: 'New', value: 'new' },
]
