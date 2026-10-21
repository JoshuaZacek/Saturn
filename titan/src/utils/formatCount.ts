const compactFormatter = new Intl.NumberFormat('en', {
  notation: 'compact',
  maximumFractionDigits: 1,
})

// 950 → "950", 2500 → "2.5k", 1200000 → "1.2m"
export const formatCompactCount = (count: number) => compactFormatter.format(count).toLowerCase()
