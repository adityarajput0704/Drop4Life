export default function BloodBadge({ group }) {
  if (!group) return null

  return (
    <span className="inline-flex items-center justify-center rounded-lg bg-[#C8102E] px-3 py-1 text-xs font-bold tracking-wide text-white">
      {group}
    </span>
  )
}

