// The live connection that brings new notifications (GET /ws on the API). It
// keeps itself open: a ping every so often (so proxies don't close it as idle),
// and after a drop it reconnects, waiting longer each time it fails.

const PING_INTERVAL_MS = 25_000
const RETRY_FIRST_MS = 1_000
const RETRY_MAX_MS = 30_000
// The API closes with this once the session has ended (logged out, account deleted).
const CLOSE_SESSION_ENDED = 4001

export type SocketEvent = { event: string; data: unknown }

type Options = {
  onEvent: (event: SocketEvent) => void
  // Each time it (re)connects: anything sent while it was down was missed.
  onOpen: () => void
  // It closed or couldn't connect, perhaps because the session has ended.
  onTrouble: () => void
}

const socketUrl = () => {
  const backendUrl = import.meta.env.VITE_BACKEND_URL as string | undefined
  if (!backendUrl) {
    return null
  }

  return `${backendUrl.replace(/\/$/, '').replace(/^http/, 'ws')}/ws`
}

export const createNotificationSocket = ({ onEvent, onOpen, onTrouble }: Options) => {
  let socket: WebSocket | null = null
  let pingTimer: ReturnType<typeof setInterval> | undefined
  let retryTimer: ReturnType<typeof setTimeout> | undefined
  let retryDelay = RETRY_FIRST_MS
  let wanted = false

  const clearTimers = () => {
    clearInterval(pingTimer)
    clearTimeout(retryTimer)
  }

  const scheduleRetry = () => {
    clearTimeout(retryTimer)
    retryTimer = setTimeout(open, retryDelay)
    retryDelay = Math.min(retryDelay * 2, RETRY_MAX_MS)
  }

  const open = () => {
    const url = socketUrl()
    if (!wanted || !url) {
      return
    }

    const current = new WebSocket(url)
    socket = current

    current.onopen = () => {
      retryDelay = RETRY_FIRST_MS
      clearInterval(pingTimer)
      pingTimer = setInterval(() => {
        if (current.readyState === WebSocket.OPEN) {
          current.send('ping')
        }
      }, PING_INTERVAL_MS)
      onOpen()
    }

    current.onmessage = (message) => {
      if (typeof message.data !== 'string' || message.data === 'pong') {
        return
      }

      try {
        onEvent(JSON.parse(message.data) as SocketEvent)
      } catch {
        // Not ours to understand; ignore it.
      }
    }

    current.onclose = (event) => {
      if (socket !== current) {
        return
      }

      clearInterval(pingTimer)
      socket = null
      if (!wanted) {
        return
      }

      onTrouble()
      if (event.code !== CLOSE_SESSION_ENDED) {
        scheduleRetry()
      }
    }
  }

  // Reconnects straight away when the device comes back online, instead of
  // waiting out the backoff.
  const onOnline = () => {
    if (wanted && !socket) {
      retryDelay = RETRY_FIRST_MS
      clearTimeout(retryTimer)
      open()
    }
  }

  const connect = () => {
    if (wanted) {
      return
    }

    wanted = true
    retryDelay = RETRY_FIRST_MS
    window.addEventListener('online', onOnline)
    open()
  }

  const disconnect = () => {
    wanted = false
    clearTimers()
    window.removeEventListener('online', onOnline)
    const current = socket
    socket = null
    current?.close()
  }

  return { connect, disconnect }
}
