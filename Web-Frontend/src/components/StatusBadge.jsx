function getStyles(status) {
  const s = String(status || '').toUpperCase()
  if (s === 'OPEN') return 'bg-[#EFF6FF] text-[#1D4ED8]'
  if (s === 'ACCEPTED') return 'bg-[#FFFBEB] text-[#B45309]'
  if (s === 'FULFILLED') return 'bg-[#F0FDF4] text-[#15803D]'
  if (s === 'CANCELLED') return 'bg-[#F9FAFB] text-[#6B7280]'
  return 'bg-[#F9FAFB] text-[#6B7280]'
}

export default function StatusBadge({ status, withDot = false }) {
  if (!status) return null
  const s = String(status).toUpperCase()

  return (
    <span className={`inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-semibold ${getStyles(s)}`}>
      {withDot && <span className="h-2 w-2 rounded-full bg-current opacity-70" />}
      {s}
    </span>
  )
}

