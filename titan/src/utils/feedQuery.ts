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

export type TimePeriod = 'day' | 'week' | 'month' | 'year' | 'all'

// How an empty Top feed names its period, and the wider one it points to.
export const timePeriodPhrases: Record<string, string> = {
  day: 'today',
  week: 'this week',
  month: 'this month',
  year: 'this year',
}

const WIDER_TIME_PERIOD: Record<string, TimePeriod> = {
  day: 'week',
  week: 'month',
  month: 'year',
  year: 'all',
}

export const widerTimePeriod = (value: string): TimePeriod | null =>
  WIDER_TIME_PERIOD[value] ?? null

export const topPostsLinkLabels: Record<TimePeriod, string> = {
  day: "See today's top posts",
  week: "See this week's top posts",
  month: "See this month's top posts",
  year: "See this year's top posts",
  all: 'See all-time top posts',
}
