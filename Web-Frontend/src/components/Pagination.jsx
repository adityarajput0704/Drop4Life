function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n))
}

export default function Pagination({ response, onPageChange }) {
  if (!response) return null

  const page = Number(response.page || 1)
  const pageSize = Number(response.page_size || 10)
  const total = Number(response.total || 0)
  const totalPages = Number(response.total_pages || 1)

  const start = total === 0 ? 0 : (page - 1) * pageSize + 1
  const end = Math.min(total, page * pageSize)

  const canPrev = Boolean(response.has_previous) && page > 1
  const canNext = Boolean(response.has_next) && page < totalPages

  const safeGo = (p) => onPageChange(clamp(p, 1, Math.max(1, totalPages)))

  return (
    <div className="flex items-center justify-between gap-3 border-t border-[#E5E7EB] bg-white px-4 py-3">
      <div className="text-sm text-[#6B7280]">
        Showing <span className="font-semibold text-[#111827]">{start}</span> to{' '}
        <span className="font-semibold text-[#111827]">{end}</span> of{' '}
        <span className="font-semibold text-[#111827]">{total}</span> requests
      </div>

      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={() => safeGo(page - 1)}
          disabled={!canPrev}
          className="rounded-lg border border-[#E5E7EB] bg-white px-3 py-2 text-sm font-semibold text-[#111827] disabled:cursor-not-allowed disabled:opacity-50"
        >
          Prev
        </button>
        <div className="rounded-lg border border-[#E5E7EB] bg-[#F7F7F7] px-3 py-2 text-sm font-semibold text-[#111827]">
          Page {page} / {totalPages}
        </div>
        <button
          type="button"
          onClick={() => safeGo(page + 1)}
          disabled={!canNext}
          className="rounded-lg border border-[#E5E7EB] bg-white px-3 py-2 text-sm font-semibold text-[#111827] disabled:cursor-not-allowed disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  )
}

