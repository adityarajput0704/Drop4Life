import { useEffect, useState } from 'react'

function Toast({ message }) {
  return (
    <div className="rounded-xl border border-[#E5E7EB] bg-white px-4 py-3 text-sm text-[#111827] shadow-sm">
      {message}
    </div>
  )
}

export default function ToastHost() {
  const [toasts, setToasts] = useState([])

  useEffect(() => {
    function onToast(event) {
      const message = event?.detail?.message
      if (!message) return

      const id = `${Date.now()}-${Math.random()}`
      setToasts((prev) => [...prev, { id, message }])

      window.setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id))
      }, 3500)
    }

    window.addEventListener('app:toast', onToast)
    return () => window.removeEventListener('app:toast', onToast)
  }, [])

  if (toasts.length === 0) return null

  return (
    <div className="fixed right-4 top-4 z-50 flex w-[320px] flex-col gap-2">
      {toasts.map((t) => (
        <Toast key={t.id} message={t.message} />
      ))}
    </div>
  )
}

