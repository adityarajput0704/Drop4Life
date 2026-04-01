function getStyles(level) {
  const s = String(level || '').toUpperCase()
  if (s === 'CRITICAL') return 'bg-[#C8102E] text-white'
  if (s === 'HIGH') return 'bg-[#F97316] text-white'
  if (s === 'MEDIUM') return 'bg-[#EAB308] text-white'
  if (s === 'LOW') return 'bg-[#22C55E] text-white'
  return 'bg-[#6B7280] text-white'
}

export default function UrgencyBadge({ level }) {
  if (!level) return null
  const s = String(level).toUpperCase()

  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[11px] font-bold ${getStyles(s)}`}>
      {s}
    </span>
  )
}

