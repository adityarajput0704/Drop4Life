import { useEffect, useMemo, useState, useCallback } from 'react'
import PageLayout from '../../components/PageLayout.jsx'
import LoadingSpinner from '../../components/LoadingSpinner.jsx'
import Pagination from '../../components/Pagination.jsx'
import BloodBadge from '../../components/BloodBadge.jsx'
import { listDonors } from '../../api/donors'
import { useWebSocket } from '../../hooks/useWebSockets.js'


function Avatar({ name }) {
  const initials = String(name || '?')
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase())
    .join('')

  const colors = ['bg-[#EFF6FF] text-[#1D4ED8]', 'bg-[#F0FDF4] text-[#15803D]', 'bg-[#FFFBEB] text-[#B45309]']
  const idx = initials ? initials.charCodeAt(0) % colors.length : 0

  return (
    <div className={`flex h-10 w-10 items-center justify-center rounded-full text-sm font-extrabold ${colors[idx]}`}>
      {initials || '?'}
    </div>
  )
}

// Resolves availability from any field name the backend might use
function resolveAvailable(d) {
  return d.availability ?? null
}


function AvailabilityBadge({ value }) {
  if (!value) {
    return (
      <span className="inline-flex items-center rounded-full bg-[#F3F4F6] px-3 py-1 text-xs font-bold text-[#6B7280]">
        UNKNOWN
      </span>
    )
  }

  const cleanValue = value.trim().toUpperCase()
  const isAvailable = cleanValue === 'AVAILABLE'

  return (
    <span
      className={[
        'inline-flex items-center rounded-full px-3 py-1 text-xs font-bold',
        isAvailable
          ? 'bg-[#F0FDF4] text-[#15803D]'
          : 'bg-pink-50 text-pink-700',
      ].join(' ')}
    >
      {cleanValue}
    </span>
  )
}



export default function Donors() {
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')

  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const handleWsEvent = useCallback((event) => {
    if (event.type === 'DONOR_AVAILABILITY_CHANGED') {
      // Refresh donor list silently
      setPage(p => p) // trigger useEffect re-run
      // Or more explicitly:
      listDonors({ page, pageSize: 10, search: search.trim() || undefined })
        .then(setData)
        .catch(console.error)
    }
  }, [page, search])

  useWebSocket('admin', handleWsEvent)

  useEffect(() => {
    let alive = true
    setLoading(true)
    setError(null)

    listDonors({ page, pageSize: 10, search: search.trim() || undefined })
      .then((d) => {
        if (!alive) return
        setData(d)
      })
      .catch((e) => {
        if (!alive) return
        setError(e)
      })
      .finally(() => {
        if (!alive) return
        setLoading(false)
      })

    return () => { alive = false }
  }, [page, search])

  const items = data?.items || []

  const stats = useMemo(() => {
    const total = data?.total ?? items.length

    const availableNow = items.filter(
      (d) => resolveAvailable(d)?.trim().toUpperCase() === 'AVAILABLE'
    ).length

    return { total, availableNow }
  }, [data, items])

  return (
    <PageLayout>
      <div className="space-y-5">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <div className="text-xl font-extrabold text-[#111827]">Donors</div>
            <div className="mt-1 text-sm font-semibold text-[#6B7280]">Donor registry and availability overview.</div>
          </div>

          <div className="flex w-full flex-col gap-3 md:w-auto md:flex-row md:items-center">
            <div className="rounded-2xl border border-[#E5E7EB] bg-white px-4 py-3 shadow-sm">
              <div className="text-xs font-semibold tracking-[0.18em] text-[#6B7280]">TOTAL DONORS</div>
              {/* data.total is the real backend count, not just current page */}
              <div className="mt-1 text-2xl font-extrabold text-[#111827]">{stats.total}</div>
            </div>
            <div className="rounded-2xl border border-[#E5E7EB] bg-white px-4 py-3 shadow-sm">
              <div className="text-xs font-semibold tracking-[0.18em] text-[#6B7280]">AVAILABLE NOW</div>
              {/* Reflects real is_available from DB — updated when Flutter donor toggles */}
              <div className="mt-1 text-2xl font-extrabold text-teal-600">{stats.availableNow}</div>
            </div>
          </div>
        </div>

        <div className="flex flex-col gap-3 rounded-2xl border border-[#E5E7EB] bg-white p-4 shadow-sm md:flex-row md:items-center md:justify-between">
          <input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            placeholder="Search donors…"
            className="h-11 w-full rounded-xl border border-[#E5E7EB] bg-white px-4 text-sm font-semibold text-[#111827] outline-none focus:border-[#C8102E] md:max-w-[320px]"
          />
          <button
            type="button"
            className="h-11 rounded-xl border border-[#E5E7EB] bg-white px-4 text-sm font-semibold text-[#111827] hover:bg-[#F7F7F7]"
          >
            Filter
          </button>
        </div>

        {loading ? <LoadingSpinner /> : null}
        {error ? (
          <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
            Failed to load donors.
          </div>
        ) : null}

        {!loading && !error ? (
          <div className="rounded-2xl border border-[#E5E7EB] bg-white shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full min-w-245">
                <thead>
                  <tr className="bg-[#F9FAFB] text-left text-xs font-semibold text-[#6B7280]">
                    <th className="px-6 py-3">DONOR NAME</th>
                    <th className="px-6 py-3">BLOOD GROUP</th>
                    <th className="px-6 py-3">CITY</th>
                    <th className="px-6 py-3">AVAILABILITY</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E5E7EB]">
                  {items.map((d) => {
                    const available = resolveAvailable(d)
                    // const active = resolveActive(d)

                    return (
                      <tr key={d.id || d.donor_id} className="text-sm text-[#111827]">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <Avatar name={d.name || d.full_name} />
                            <div>
                              <div className="font-semibold">{d.name || d.full_name || '-'}</div>
                              <div className="mt-1 text-xs font-semibold text-[#6B7280]">
                                ID: {d.donor_id || d.id || '-'}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <BloodBadge group={d.blood_group || d.group} />
                        </td>
                        <td className="px-6 py-4 font-semibold text-[#6B7280]">{d.city || '-'}</td>
                        <td className="px-6 py-4">
                          {/* Reads is_available from backend — reflects Flutter donor toggle in real time */}
                          <AvailabilityBadge value={available} />
                        </td>
                      </tr>
                    )
                  })}
                  {items.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="px-6 py-10 text-center text-sm font-semibold text-[#6B7280]">
                        No donors found.
                      </td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </div>

            <Pagination response={data} onPageChange={setPage} />
          </div>
        ) : null}
      </div>
    </PageLayout>
  )
}