export const MIN_LOADING_VISIBLE_MS = 500

export const waitForMinimumVisibleTime = async (
  startedAt: number,
  minimumVisibleMs: number = MIN_LOADING_VISIBLE_MS,
) => {
  const elapsed = Date.now() - startedAt
  const remaining = minimumVisibleMs - elapsed

  if (remaining > 0) {
    await new Promise<void>((resolve) => {
      setTimeout(resolve, remaining)
    })
  }
}
