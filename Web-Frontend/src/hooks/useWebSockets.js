import { useEffect, useRef, useCallback } from 'react'

/**
 * Connects to a WebSocket room and calls onMessage when events arrive.
 * Auto-reconnects if connection drops.
 *
 * @param {string} room  - e.g. "admin" or "hospital_3"
 * @param {function} onMessage - called with parsed event object
 */
export function useWebSocket(room, onMessage) {
  const wsRef = useRef(null)
  const reconnectTimer = useRef(null)
  const onMessageRef = useRef(onMessage)

  // Keep onMessage ref fresh without re-triggering effect
  useEffect(() => {
    onMessageRef.current = onMessage
  }, [onMessage])

  const connect = useCallback(() => {
    if (!room) return

    const base = (import.meta.env.VITE_API_URL || 'http://localhost:8000')
      .replace('https://', 'wss://')
      .replace('http://', 'ws://')

    const url = `${base}/ws/${room}`
    const ws = new WebSocket(url)
    wsRef.current = ws

    ws.onopen = () => {
      console.info(`[WS] connected → ${room}`)
      // Clear any pending reconnect
      if (reconnectTimer.current) {
        clearTimeout(reconnectTimer.current)
        reconnectTimer.current = null
      }
    }

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        onMessageRef.current?.(data)
      } catch {
        // ignore malformed messages
      }
    }

    ws.onclose = () => {
      console.info(`[WS] disconnected → ${room}, reconnecting in 3s`)
      // Auto-reconnect after 3 seconds
      reconnectTimer.current = setTimeout(connect, 3000)
    }

    ws.onerror = (err) => {
      console.warn(`[WS] error → ${room}`, err)
      ws.close()
    }
  }, [room])

  useEffect(() => {
    connect()
    return () => {
      // Cleanup on unmount
      if (reconnectTimer.current) clearTimeout(reconnectTimer.current)
      wsRef.current?.close()
    }
  }, [connect])
}